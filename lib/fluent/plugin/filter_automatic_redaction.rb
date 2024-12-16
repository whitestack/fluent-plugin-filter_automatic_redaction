require 'fluent/error'
require 'fluent/plugin/filter'
require 'fluent/plugin/parser'

module Fluent::Plugin
  class AutomaticRedaction < Filter
    Fluent::Plugin.register_filter('automatic_redaction', self)

    DEFAULT_MAX_LENGTH = 1000
    DEFAULT_TIMEOUT = 1.0

    attr_accessor :timeout_checker
    attr_accessor :patterns_hash

    config_param :input_key, :string
    config_param :redactors, :string
    config_param :output_key, :string
    config_param :max_length, :integer, :default => DEFAULT_MAX_LENGTH
    config_param :timeout, :float, :default => DEFAULT_TIMEOUT

    def configure(conf)
      super
      @max_length = @max_length.to_i <= 0 ? DEFAULT_MAX_LENGTH : @max_length.to_i
      @timeout_checker = Parser::TimeoutChecker.new(@timeout.to_f <= 0.0 ? DEFAULT_TIMEOUT : @timeout.to_f)
    end

    def start
      super
      @timeout_checker.start
    end

    def stop
      super
      @timeout_checker.stop
    end

    def parse_patterns_hash
      if @patterns_hash.nil?
        @patterns_hash = Hash.new
        nested_patterns_hash = Hash.new
        patterns_template = File.read("#{File.dirname(__FILE__)}/patterns_template/grok-patterns.erb")
        patterns_template.each_line do |line|
          unless line == "\n" || line.start_with?("#")
            line_split = line.split
            if line_split.size == 2
              key, value = line_split
              value_scan = value.scan(/(?<=%{).*?(?=})/)  # %{}
              if value_scan.size == 0
                @patterns_hash[key] = value
              else
                nested_patterns_hash[key] = {'placeholders' => value_scan, 'pattern' => value}
              end
            end
          end
        end
        unless nested_patterns_hash.empty?
          nested_patterns_hash.each do |key, value|
            placeholders = value['placeholders']
            pattern = value['pattern']
            placeholders.each do |placeholder|
              placeholder_split = placeholder.split(':')
              if placeholder_split.size == 1
                pattern = pattern.gsub("%{#{placeholder}}", @patterns_hash[placeholder])  # %{}
              else
                placeholder_split[0] = @patterns_hash[placeholder_split[0]]
                pattern = pattern.gsub("%{#{placeholder}}", placeholder_split.join(":"))  # %{}
              end
            end
            @patterns_hash[key] = pattern
          end
        end
      end
    end

    def filter(tag, time, record)
      parse_patterns_hash
      redactors = @redactors.split(',')
      if record.key?(@input_key)
        value = record[@input_key]
        value_length = value.length
        if value_length <= @max_length
          faulty_redactors = Array.new
          redactors.each { |redactor|
            begin
              @timeout_checker.execute {
                value = value.gsub(/#{Regexp.new(@patterns_hash[redactor])}/, "<#{redactor}>")
              }
            rescue Fluent::UncatchableError => e
              faulty_redactors << redactor
              puts "TimeoutChecker: #{e.message}"
            end
          }
          unless faulty_redactors.empty?
            record['faulty_redactors'] = faulty_redactors
            puts "Faulty redactors: #{faulty_redactors.join(',')}"
          end
        else
          record['faulty_log_length'] = {"length" => value_length, "max_length" => @max_length}
          puts "Faulty log length: #{value_length}", "Max. length: #{@max_length}"
        end
        record[@output_key] = value
      else
        puts "Non-existent 'input_key': '#{@input_key}'"
      end
      record
    end

  end
end