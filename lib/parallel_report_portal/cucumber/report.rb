require 'faraday'
require 'cucumber/formatter/hook_query_visitor'

require_relative 'array_decorator'

module ParallelReportPortal
  module Cucumber
    class Report
      
      attr_reader :launch_id
      
      Feature = Struct.new(:feature, :id)
      
      LOG_LEVELS = { 
        error: 'ERROR', 
        warn: 'WARN', 
        info: 'INFO', 
        debug: 'DEBUG', 
        trace: 'TRACE', 
        fatal: 'FATAL', 
        unknown: 'UNKNOWN' 
      }
      
      def initialize(start_time, background_queue)
        @http = http_connection
        @feature = nil
        @queue = background_queue
      end
      
      def launch_started(start_time)
        f = File.new(Report.launch_id_file, 'a+')
        begin
          f.flock(File::LOCK_EX)
          if f.size == 0
            description = 'test launch'
            resp = @http.post('launch') do |req|
              req.body = {
                name: 'Parallel', 
                start_time: start_time, 
                tags: [], 
                description: 'a description', 
                mode: 'DEBUG'
              }.to_json
            end
            @launch_id = JSON.parse(resp.body)['id'] if resp.success?
            f.write(launch_id)
          else
            @launch_id = f.readline
          end
        ensure
          f.flock(File::LOCK_UN)
          f.close
        end
      end
      
      def launch_finished(clock)
        resp = @http.put("launch/#{launch_id}/finish") do |req|
          req.body = { end_time: clock }.to_json
        end
      end
      
      def feature_started(feature, clock)
        resp = @http.post('item') do |req|
          req.body = {
            start_time: clock,
            name: "#{feature.keyword}: #{feature.name}",
            type: 'TEST',
            launch_id: launch_id,
            tags: feature.tags.map(&:name),
            description: feature.file
          }.to_json
        end
        feature_id = JSON.parse(resp.body)['id'] if resp.success?
      end
      
      def feature_finished(clock)
        if @feature
          resp = @http.put("item/#{@feature.id}") do |req|
            req.body = { end_time: clock }.to_json
          end
        end
      end
            
      def test_case_started(event, clock)
        test_case = event.test_case
        feature = current_feature(test_case.feature, clock)
        resp = @http.post("item/#{@feature.id}") do |req|
          req.body = {
            start_time: clock,
            tags: test_case.tags.map(&:name),
            name: "#{test_case.keyword}: #{test_case.name}",
            type: 'STEP',
            launch_id: launch_id,
            description: test_case.location.to_s
          }.to_json
        end
        @test_case_id = JSON.parse(resp.body)['id'] if resp.success?
      end
      
      def test_case_finished(event, clock)
        test_case = event.test_case
        result = event.result
        status = result.to_sym
        failure_message = nil
        if [:undefined, :pending].include?(status)
          status = :failed
          failure_message = result.message
        end
        resp = @http.put("item/#{@test_case_id}") do |req|
          req.body = {
            end_time: clock,
            status: status
          }.to_json
        end
      end
      
      def test_step_started(event, clock)
        @queue << proc do
          test_step = event.test_step
          if not_a_hook?(test_step)
            step_source = test_step.source.last
            detail = "#{step_source.keyword} #{step_source.text}"
            if step_source.multiline_arg.doc_string?
              detail << %(\n"""\n#{step_source.multiline_arg.content}\n""")
            elsif step_source.multiline_arg.data_table?
              detail << step_source.multiline_arg.raw.reduce("\n") {|acc, row| acc << "| #{row.join(' | ')} |\n"}
            end
            resp = @http.post('log') do |req|
              req.body = {
                item_id: @test_case_id,
                message: detail,
                level: status_to_level(:trace),
                time: clock,
              }.to_json
            end
          end
        end
      end
      
      def test_step_finished(event, clock)
        @queue << proc do
          test_step = event.test_step
          result = event.result
          status = result.to_sym
          if not_a_hook?(test_step)
            step_source = test_step.source.last
            detail = "#{step_source.text}"
          
            if [:failed, :pending, :undefined].include?(status)
              level = :error
              detail = if [:failed, :pending].include?(status)
                         ex = result.exception
                         sprintf("%s: %s\n  %s", ex.class.name, ex.message, ex.backtrace.join("\n  "))
                       else
                         sprintf("Undefined step: %s:\n%s", test_step.text, test_step.source.last.backtrace_line)
                       end
              @http.post('log') do |req|
                req.body = { 
                  item_id: @test_case_id,
                  time: clock,
                  level: level,
                  message: detail
                }.to_json
              end
            end
          end
        end
      end
    
      private
      
      at_exit do
        if Report.parallel?
          if ParallelTests.first_process?
            ParallelTests.wait_for_other_processes_to_finish
            File.delete(Report.launch_id_file)
          end
        else
          File.delete(Report.launch_id_file)
        end
      end
      
      def self.launch_id_file
        pid = Report.parallel? ? Process.ppid : Process.pid
        @lock_file ||= Pathname(Dir.tmpdir) + ("report_portal_tracking_file_#{pid}.lck")
      end
      
      def self.parallel?
        !ENV['PARALLEL_PID_FILE'].nil?
      end
      
      def current_feature(feature, clock)
        if @feature&.feature == feature
          @feature
        else
          feature_finished(clock)
          @feature = Feature.new(feature, feature_started(feature, clock))
        end
      end
      
      def not_a_hook?(test_step)
        !::Cucumber::Formatter::HookQueryVisitor.new(test_step).hook?
      end
      
      def status_to_level(status)
        case status
        when :passed
          LOG_LEVELS[:info]
        when :failed, :undefined, :pending, :error
          LOG_LEVELS[:error]
        when :skipped
          LOG_LEVELS[:warn]
        else
          LOG_LEVELS.fetch(status, LOG_LEVELS[:info])
        end
      end
      
      def http_connection
        url = "https://report-portal.int-ac.dvla.gov.uk/api/v1/tacho-drivers-card"
        Faraday.new(
          url: url,
          headers: {
            'Content-Type'  => 'application/json',
            'Authorization' => "Bearer a0f7e79c-381d-44ab-8d03-f7143207691e"
          }
        )
      end
    
    end
  end
end