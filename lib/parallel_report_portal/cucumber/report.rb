require 'faraday'
require 'tree'
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
      
      def initialize(start_time)
        @feature = nil
        @tree = Tree::TreeNode.new( 'root' ) 
      end
      
      def launch_started(start_time)
        ParallelReportPortal.file_open_exlock_and_block(ParallelReportPortal.launch_id_file, 'a+' ) do |file|
          if file.size == 0
            @launch_id = ParallelReportPortal.req_launch_started(start_time)
            file.write(@launch_id)
            file.flush
          else
             @launch_id = file.readline
          end
        end
      end
      
      def launch_finished(clock)
        @tree.postordered_each do |node|
          ParallelReportPortal.req_feature_finished(node.content, clock) unless node.is_root?
        end
        ParallelReportPortal.req_launch_finished(launch_id, clock)
      end
      
      def feature_started(feature, clock)
        parent_id = hierarchy(feature, clock)
        ParallelReportPortal.req_feature_started(launch_id, parent_id, feature, clock)
      end
      
      def feature_finished(clock)
        if @feature
          resp = ParallelReportPortal.req_feature_finished(@feature.id, clock)
        end
      end
            
      def test_case_started(event, clock)
        test_case = event.test_case
        feature = current_feature(test_case.feature, clock)
        @test_case_id = ParallelReportPortal.req_test_case_started(launch_id, feature.id, test_case, clock)
      end
      
      def test_case_finished(event, clock)
        result = event.result
        status = result.to_sym
        failure_message = nil
        if [:undefined, :pending].include?(status)
          status = :failed
          failure_message = result.message
        end
        resp = ParallelReportPortal.req_test_case_finished(@test_case_id, status, clock)
      end
      
      def test_step_started(event, clock)
        test_step = event.test_step
        if !hook?(test_step)
          step_source = test_step.source.last
          detail = "#{step_source.keyword} #{step_source.text}"
          if step_source.multiline_arg.doc_string?
            detail << %(\n"""\n#{step_source.multiline_arg.content}\n""")
          elsif step_source.multiline_arg.data_table?
            detail << step_source.multiline_arg.raw.reduce("\n") {|acc, row| acc << "| #{row.join(' | ')} |\n"}
          end
          
          ParallelReportPortal.req_log(@test_case_id, detail, status_to_level(:trace), clock)
        end
      end
      
      def test_step_finished(event, clock)
        test_step = event.test_step
        result = event.result
        status = result.to_sym
        if !hook?(test_step)
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
            
            ParallelReportPortal.req_log(@test_case_id, detail, level, clock)
          end
        end
      end
    
      private
      
      def hierarchy(feature, clock)
        node = nil
        path_components = feature.location.file.split(File::SEPARATOR)
        ParallelReportPortal.file_open_exlock_and_block(ParallelReportPortal.hierarchy_file, 'a+b' ) do |file|
          @tree = Marshal.load(File.read(file)) if file.size > 0 
          node = @tree.root
          path_components[0..-2].each do |component|
            next_node = node[component]
            unless next_node
              id = ParallelReportPortal.req_hierarchy(launch_id, "Folder: #{component}", node.content, 'SUITE', [], nil, clock )
              next_node = Tree::TreeNode.new(component, id)
              node << next_node
              node = next_node
            else
              node = next_node
            end
          end
          file.truncate(0)
          file.write(Marshal.dump(@tree))
          file.flush
        end
        
        node.content
      end
      
      def current_feature(feature, clock)
        if @feature&.feature == feature
          @feature
        else
          feature_finished(clock)
          @feature = Feature.new(feature, feature_started(feature, clock))
        end
      end
      
      def hook?(test_step)
        ::Cucumber::Formatter::HookQueryVisitor.new(test_step).hook?
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
      
    
    end
  end
end