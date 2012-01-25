# Iconomus

## Setup

The following is the setup process for the Rails 3.2 project:

    $ rails new . --database=postgresql --skip-test-unit

Use the following commands to setup your Postgres database:

    $ createuser --superuser iconomus
    $ createdb -U iconomus iconomus
    $ createdb -U iconomus iconomus_test
    $ rake db:create
    $ rake db:migrate
    $ rake db:test:prepare

## Tests

Iconomus uses RSpec for tests.

    $ rake test

To speed up development, it's suggested that you use Spork to preload your
tests.


## Deployment

Run the following command to deploy to Heroku:

    $ git push heroku master
