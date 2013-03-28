# services-to-omnifocus

This is a collection of scripts that I wrote to poll two services I use on a daily basis for tasks that require my attention and pipe them into OmniFocus.

They have some built-in intelligence to sync changes back and forth, but it only goes so far.

## Supported services

As of this writing, scripts to query the APIs of [Zendesk](http://zendesk.com), [Highrise](http://highrisehq.com), [GitHub](http://github.com/) Issues, and [Trello](http://trello.com/) are included. See the notes in the header of the respective plugins for implementation notes.

## Setting up

The scripts expect your site-specific URLs, API keys, and passwords as environment variables. A sample environment is included as `env.sample`. This typically does into your `~/.zshrc` or `~/.bashrc`.

The API dependencies and such are managed with bundler. After cloning the repository, install those dependencies with `bundle` in the repository directory.

## Running

I run the master script (`services-to-omnifocus.rb`) from a [Keyboard Maestro](http://keyboardmaestro.com) macro. It will run all of the plugins contained in the `plugins` subdirectory. If you don't care about a particular service, move its plugin into the `plugins_disabled` directory.

You can also run it through launchd, on login, etc.

## Customizing

This is currently highly bent towards my personal needs. I'm sharing it in case anyone else finds it useful. If you have something to share back, please open a pull request.
