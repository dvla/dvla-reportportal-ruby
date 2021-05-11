require 'faraday'
require 'tree'

module ParallelReportPortal
  module Cucumber
    # Report object. This handles the management of the state hierarchy and
    # the issuing of the requests to the HTTP module. 
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

      
      # Create a new instance of the report
      def initialize(ast_lookup = nil)
        @feature = nil
        @tree = Tree::TreeNode.new( 'root' ) 
        @ast_lookup = ast_lookup
      end
      
      # Issued to start a launch. It is possilbe that this method could be called
      # from multiple processes for the same launch if this is being run with
      # parallel tests enabled. A temporary launch file will be created (using
      # exclusive locking). The first time this method is called it will write the
      # launch id to the launch file, subsequent calls by other processes will read
      # this launch id and use that.
      # 
      # @param start_time [Integer] the millis from the epoch 
      # @return [String] the UUID of this launch
      def launch_started(start_time)
        ParallelReportPortal.file_open_exlock_and_block(ParallelReportPortal.launch_id_file, 'a+' ) do |file|
          if file.size == 0
            @launch_id = ParallelReportPortal.req_launch_started(start_time)
            file.write(@launch_id)
            file.flush
          else
             @launch_id = file.readline
          end
          @launch_id
        end
      end
      
      # Called to finish a launch. Any open children items will be closed in the process.
      # 
      # @param clock [Integer] the millis from the epoch
      def launch_finished(clock)
        @tree.postordered_each do |node|
          ParallelReportPortal.req_feature_finished(node.content, clock) unless node.is_root?
        end
        ParallelReportPortal.req_launch_finished(launch_id, clock)
      end
      
      # Called to indicate that a feature has started.
      # 
      # @param 
      def feature_started(feature, clock)
        parent_id = hierarchy(feature, clock)
        feature = feature.feature if using_cucumber_messages?
        ParallelReportPortal.req_feature_started(launch_id, parent_id, feature, clock)
      end
      
      def feature_finished(clock)
        if @feature
          resp = ParallelReportPortal.req_feature_finished(@feature.id, clock)
        end
      end
            
      def test_case_started(event, clock)
        test_case = lookup_test_case(event.test_case)
        feature = lookup_feature(event.test_case)
        feature = current_feature(feature, clock)
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
          step_source = lookup_step_source(test_step)
          detail = "#{step_source.keyword} #{step_source.text}"
          if (using_cucumber_messages? ? test_step : step_source).multiline_arg.doc_string?
            detail << %(\n"""\n#{(using_cucumber_messages? ? test_step : step_source).multiline_arg.content}\n""")
          elsif (using_cucumber_messages? ? test_step : step_source).multiline_arg.data_table?
            detail << (using_cucumber_messages? ? test_step : step_source).multiline_arg.raw.reduce("\n") {|acc, row| acc << "| #{row.join(' | ')} |\n"}
          end
          
          ParallelReportPortal.req_log(@test_case_id, detail, status_to_level(:trace), clock)
        end
      end
      
      def test_step_finished(event, clock)
        test_step = event.test_step
        result = event.result
        status = result.to_sym
        detail = nil
        if [:failed, :pending, :undefined].include?(status)
          if [:failed, :pending].include?(status)
            ex = result.exception
            detail = sprintf("%s: %s\n  %s", ex.class.name, ex.message, ex.backtrace.join("\n  "))
          elsif !hook?(test_step)
            step_source = lookup_step_source(test_step)
            detail = sprintf("Undefined step: %s:\n%s", step_source.text, step_source.source.last.backtrace_line)
          end
        elsif !hook?(test_step)
          step_source = lookup_step_source(test_step)
          detail = "#{step_source.text}"
        end
        ParallelReportPortal.req_log(@test_case_id, detail, status_to_level(status), clock) if detail

      end
    
      private

      def using_cucumber_messages?
        @ast_lookup != nil
      end
      
      def hierarchy(feature, clock)
        node = nil
        path_components = if using_cucumber_messages?
                            feature.uri.split(File::SEPARATOR)
                          else
                            feature.location.file.split(File::SEPARATOR)
                          end
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

      def lookup_feature(test_case)
        if using_cucumber_messages?
          @ast_lookup.gherkin_document(test_case.location.file)
        else
          test_case.feature
        end
      end

      def lookup_test_case(test_case)
        if using_cucumber_messages?
          @ast_lookup.scenario_source(test_case).scenario
        else
          test_case
        end
      end

      def lookup_step_source(step)
        if using_cucumber_messages?
          @ast_lookup.step_source(step).step
        else
          step.source.last
        end
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
        if using_cucumber_messages?
          test_step.hook?
        else
          ! test_step.source.last.respond_to?(:keyword)
        end
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