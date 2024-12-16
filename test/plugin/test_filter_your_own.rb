require 'json'
require 'fluent/test'
require 'fluent/test/driver/filter'
require 'fluent/test/helpers'
require 'fluent/plugin/filter_automatic_redaction'
require 'test/unit'


class MyFilterTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    input_key input_message
    redactors <REDACTORS>
    output_key output_message
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::AutomaticRedaction).configure(conf)
  end

  def parse_logs_files(json_logs_file)
    messages = JSON.parse(File.read("#{File.dirname(__FILE__)}/logs_files/messages/#{json_logs_file}"))
    expected = JSON.parse(File.read("#{File.dirname(__FILE__)}/logs_files/expected/#{json_logs_file}"))
    [messages, expected]
  end

  def filter(config, messages)
    d = create_driver(config)
    d.run do
      messages.each do |message|
        d.feed('test', event_time('2024-10-22T20:08:14.378813+00:00'), message)
      end
    end
    d.filtered_records
  end

  def assert_redacted_logs_from_file(json_logs_file, redactors, conf=CONFIG)
    messages, expected = parse_logs_files(json_logs_file)
    filtered_records = filter(conf.sub('<REDACTORS>', redactors), messages)
    assert_equal(expected, filtered_records)
  end

  sub_test_case 'invalid configuration' do
    test 'empty configuration' do
      conf = ''
      assert_raise(Fluent::ConfigError) do
        create_driver(conf)
      end
    end

    test 'invalid parameter' do
      conf = %[
        invalid_key invalid_value
      ]
      assert_raise(Fluent::ConfigError) do
        create_driver(conf)
      end
    end
  end

  sub_test_case 'automatic redaction' do
    test 'NON-FILTERED' do
      assert_redacted_logs_from_file('00_non-filtered.json', 'UUID,HOSTPORT')
    end

    test 'UUID & HOSTPORT' do
      assert_redacted_logs_from_file('01_uuid_hostport.json', 'UUID,HOSTPORT')
    end

    test 'EMAILADDRESS' do
      assert_redacted_logs_from_file('02_emailaddress.json', 'EMAILADDRESS')
    end

    test 'QUOTEDSTRING' do
      assert_redacted_logs_from_file('03_quotedstring.json', 'QUOTEDSTRING')
    end

    test 'URN' do
      assert_redacted_logs_from_file('04_urn.json', 'URN')
    end

    test 'MAC' do
      assert_redacted_logs_from_file('05_macaddress.json', 'MAC')
    end

    test 'URI' do
      conf = %[
        input_key input_message
        redactors <REDACTORS>
        output_key output_message
        max_length 1500
      ]
      assert_redacted_logs_from_file('06_uri.json', 'URI', conf)
    end

    test 'PATH' do
      assert_redacted_logs_from_file('07_path.json', 'PATH')
    end

    test 'TIMESTAMP_ISO8601' do
      assert_redacted_logs_from_file('08_timestamp_iso8601.json', 'TIMESTAMP_ISO8601')
    end

    test 'LOGLEVEL' do
      assert_redacted_logs_from_file('09_loglevel.json', 'LOGLEVEL')
    end

    test 'MAC & IP' do
      assert_redacted_logs_from_file('10_macaddress_ipaddress.json', 'MAC,IP')
    end
  end

end