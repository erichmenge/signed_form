# SignedForm

[![Gem Version](https://badge.fury.io/rb/signed_form.png)](http://badge.fury.io/rb/signed_form)
[![Build Status](https://travis-ci.org/erichmenge/signed_form.png?branch=master)](https://travis-ci.org/erichmenge/signed_form)
[![Code Climate](https://codeclimate.com/github/erichmenge/signed_form.png)](https://codeclimate.com/github/erichmenge/signed_form)
[![Coverage Status](https://coveralls.io/repos/erichmenge/signed_form/badge.png?branch=master)](https://coveralls.io/r/erichmenge/signed_form)

SignedForm brings new convenience and security to your Rails 4 or Rails 3 application.

SignedForm is under active development. Please make sure you're reading the README associated with the version of
SignedForm you're using. Click the tag link on GitHub to switch to the version you've installed to get the correct
README.

Or be brave and bundle the gem straight from GitHub master.

A nicely displayed version of this README complete with table of contents is available
[here](http://erichmenge.com/signed_form/).

## How It Works

Traditionally, when you create a form with Rails you enter your fields using something like `f.text_field :name` and so
on.  Once you're done making your form you need to make sure that you've either set those parameters as accessible in
the model (Rails 3) or use `permit` (Rails 4). This is redundant. Why would you make a form for a user to fill out and
then not accept their input? You need to always maintain this synchronization.

SignedForm generates a list of attributes that you have in your form and attaches them to be submitted with the form
along with a HMAC-SHA1 signature of those attributes to protect them from tampering. That means no more `permit` and
no more `attr_accessible`. It just works.

What this looks like:

```erb
<%= signed_form_for(@user) do |f| %>
  <% f.add_signed_fields :zipcode, :state # Optionally add additional fields to sign %>

  <%= f.text_field :name %>
  <%= f.text_field :address %>
  <%= f.submit %>
<% end %>
```

```ruby
UsersController < ApplicationController
  def create
    @user = User.find params[:id]
    @user.update_attributes params[:user]
  end
end
```

That's it. You're done. Need to add a field? Pop it in the form. You don't need to then update a list of attributes.

Of course, you're free to continue using the standard `form_for`. `SignedForm` is strictly opt-in. It won't change the
way you use standard forms.

## More than just Convenience &mdash; Security

SignedForm protects you in 3 ways:

* Form fields are signed, so no alteration of the fields are allowed.
* Form actions are signed. That means a form with an action of `/admin/users/3` will not work when submitted to `/users/3`.
* Form views are digested (see below). So if you remove a field from your form, old forms will not be accepted despite
  a valid signature.

The second two methods of security are optional and can be turned off globally or on a form by form basis.

## Requirements

SignedForm requires:

* Ruby 1.9 or later
* Rails 4 or Rails 3.1+ ([strong_parameters](https://github.com/rails/strong_parameters) gem
  required for Rails 3)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'signed_form'
```

And then execute:

    $ bundle

If you're using Rails 3, you'll also need to install the [strong_parameters](https://github.com/rails/strong_parameters)
gem. Please set it up as instructed on the linked GitHub repo.

If you're using Rails 4, it works out of the box.

You'll need to include `SignedForm::ActionController::PermitSignedParams` in the controller(s) you want to use
SignedForm with. This can be done application wide by adding the `include` to your ApplicationController.

```ruby
ApplicationController < ActionController::Base
  include SignedForm::ActionController::PermitSignedParams

  # ...
end
```

You'll also need to create an initializer:

```shell
$ echo "SignedForm.secret_key = '$(rake secret)'" > config/initializers/signed_form.rb
```

You'll probably want to keep this out of version control. Treat this key like you would your session secret, keep it
private.

## Support for other Builders

* [SimpleForm Adapter](https://github.com/erichmenge/signed_form-simple_form)

## Form Digests

SignedForm will create a digest of all the views/partials involved with rendering your form. If the form is modifed old
forms will be expired. This is done to eliminate the possibility of old forms coming back to bite you.

By default, there is a 5 minute grace period before old forms will be rejected. This is done so that if you make a
trivial change to a form you won't prevent a form a user is currently filling out from being accepted when you
restart your server.

Of course if a critical mistake is made (such as allowing an admin field to be set in the form) you could change the
secret key to prevent any old form from getting through.

By default, these digests are not cached. That means that each form that is submitted will have the views be digested
again. Most views and partials are relatively small so the cost of computing the MD5 hash of the files is not very
expensive. However, if this is something you care about SignedForm also provides a memory store
(`SignedForm::DigestStores::MemoryStore`) that will cache the digests in memory. Other stores could be used as well, as
long as the class instance responds to `#fetch` taking the cache key as an argument as well as the block that will
return the stored digest.

## Example Configuration

An example config/initializers/signed_form.rb might look something like this (these are the defaults, with the exception
of the key of course):

```ruby
SignedForm.config do |c|
  c.options[:sign_destination]    = true
  c.options[:digest]              = true
  c.options[:digest_grace_period] = 300

  c.digest_store = SignedForm::DigestStores::NullStore.new
  c.secret_key   = 'supersecret'
end

```

Those options that are in the options hash are the default per-form options. They can be overridden by passing the same
option to the `signed_form_for` method.

## I want to hear from you

If you're using SignedForm, I'd love to hear from you. What do you like? What could be better? I'd love to hear your
ideas. Join the mailing list on librelist to join the discussion at [signedform@librelist.com](mailto:signedform@librelist.com).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
