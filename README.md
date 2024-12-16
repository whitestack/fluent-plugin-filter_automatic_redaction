# Fluent::Plugin::AutomaticRedaction

Fluentd can be used to perform text redaction on received events. This
mechanism is heavily based on [Logstash redact
processor](https://www.elastic.co/guide/en/elasticsearch/reference/current/redact-processor.html), so you may like
to read about it first.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-filter_automatic_redaction'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install fluent-plugin-filter_automatic_redaction

## Usage

In Fluentd, text fields can be redacted by using our own custom _Automatic Redaction plugin_. This is managed
entirely via Fluentd configuration blocks, like any other filter plugin. The syntax requires at least three
parameters: `input_key`, `output_key` and `redactors`.
For example, the following configuration block can be used to apply the `UUID` and the `HOSTPORT` redactors on the
`message` field of some WhiteCloud events:
```text
<filter **>
  @type automatic_redaction
  input_key message
  redactors HOSTPORT,UUID
  output_key log_normalized
</filter>
```
Thus, if the input logs (i.e. `message` field of each record) are the following:
```text
oslo.messaging._drivers.impl_rabbit [-] [76ff78aa-c627-4858-9e9e-33bb74ee97aa] AMQP server on 10.218.15.43:5672 is unreachable: [Errno 111] ECONNREFUSED.
oslo.messaging._drivers.impl_rabbit [-] [c64376c4-d5bc-4e82-987c-6e31119ed9fe] AMQP server on 10.218.15.35:5672 is unreachable: [Errno 111] ECONNREFUSED.
oslo.messaging._drivers.impl_rabbit [-] [c64376c4-d5bc-4e82-987c-6e31119ed9fe] AMQP server on 10.218.15.43:5672 is unreachable: [Errno 111] ECONNREFUSED.
oslo.messaging._drivers.impl_rabbit [-] [76ff78aa-c627-4858-9e9e-33bb74ee97aa] AMQP server on 10.218.15.12:5672 is unreachable: [Errno 111] ECONNREFUSED.
```
The plugin will _modify_ the records, adding a _new field_ `log_normalized` with the following data:
```text
oslo.messaging._drivers.impl_rabbit [-] [<UUID>] AMQP server on <HOSTPORT> is unreachable: [Errno 111] ECONNREFUSED.
oslo.messaging._drivers.impl_rabbit [-] [<UUID>] AMQP server on <HOSTPORT> is unreachable: [Errno 111] ECONNREFUSED.
oslo.messaging._drivers.impl_rabbit [-] [<UUID>] AMQP server on <HOSTPORT> is unreachable: [Errno 111] ECONNREFUSED.
oslo.messaging._drivers.impl_rabbit [-] [<UUID>] AMQP server on <HOSTPORT> is unreachable: [Errno 111] ECONNREFUSED.
```
> **NOTE:**
>
>To avoid causing a bottleneck, the plugin will not process text fields with more than 1000 characters by default. Also, the processing time for each record is bounded to 1 second by default. Both of these configurations can be overridden with the optional parameters `max_length` and `timeout`.
>
>A complete list of all available redactors and their regex patterns can be found [on the plugin
repository](https://github.com/whitestack/fluent-plugin-filter_automatic_redaction/blob/main/lib/fluent/plugin/patterns_template/grok-patterns.erb). You can also add your own redactors to the current list and they will just work.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/whitestack/fluent-plugin-filter_automatic_redaction. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/whitestack/fluent-plugin-filter_automatic_redaction/blob/main/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fluent::Plugin::AutomaticRedaction project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/whitestack/fluent-plugin-filter_automatic_redaction/blob/main/CODE_OF_CONDUCT.md).
