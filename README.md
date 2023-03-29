# Discourse Subscription Client Gem
This gem is only for use with Discourse plugins. It provides subscription client support to a Discourse plugin, primarily for use with the Discourse Subscription Server plugin.

## Installation
Add this line to your plugin's `plugin.rb` file

```ruby
gem "discourse_subscription_client", "0.1.0.pre11", require_name: "discourse_subscription_client"
```

## Usage

The gem API is accessible through the `DiscourseSubscriptionClient` class. Supported methods are described below.

### find_subscriptions

```ruby
DiscourseSubscriptionClient.find_subscriptions(resource_name)
```

#### Arguments

##### resource_name

The name of a resource defined in the `discourse-subscription-server` plugin's `subscription_server_subscriptions` setting.

#### Returns

Returns a `DiscourseSubscriptionClient::Subscriptions::Result` object, containing the supplier, resource and any active subscriptions.

#### Example

```ruby
result = DiscourseSubscriptionClient.find_subscriptions("discourse-custom-wizard")
result.supplier # <DiscourseSubscriptionSupplier name="Pavilion" ...>
result.resource # <DiscourseSubscriptionResource name="discourse-custom-wizard" ...>
result.subscriptions # [<DiscourseSubscriptionSubscription product_name="Business" ...>]
```

## Development

### Tests
The gem has to create a dummy Discourse environment when running specs, so there are a few testing quirks.

Discourse migrations go in `db/migrate` as normal. They are including in the rails migrations_paths in `lib/discourse_subscription_client/engine.rb`.

If you add new migrations, run test migrations as normal (from the root of the gem)

```
RAILS_ENV=test rake db:drop db:create db:migrate
```

If you're not adding new migrations you only need to load the schema. If you are running migrations you need to also load the schema (in addition to running the migrations)

```
RAILS_ENV=test rake db:schema:load
```

## License
The gem is available as open source under the terms of the [GNU GPL v2 License](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html).
