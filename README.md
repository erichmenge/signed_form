# SignedForm

[![Gem Version](https://badge.fury.io/rb/signed_form.png)](http://badge.fury.io/rb/signed_form)
[![Build Status](https://travis-ci.org/erichmenge/signed_form.png?branch=master)](https://travis-ci.org/erichmenge/signed_form)
[![Code Climate](https://codeclimate.com/github/erichmenge/signed_form.png)](https://codeclimate.com/github/erichmenge/signed_form)
[![Coverage Status](https://coveralls.io/repos/erichmenge/signed_form/badge.png?branch=master)](https://coveralls.io/r/erichmenge/signed_form)

SignedForm brings new convenience and security to your Rails 4 or Rails 3 application.

## How It Works

Traditionally, when you create a form with Rails you enter your fields using something like `f.text_field :name` and so
on.  Once you're done making your form you need to make sure that you've either set those parameters as accessible in
the model (Rails 3) or use `permit` (Rails 4). This is redundant. Why would you make a form for a user to fill out and
then not accept their input? You need to always maintain this synchronization.

SignedForm generates a list of attributes that you have in your form and attaches them to be submitted with the form
along with a HMAC-SHA1 signature of those attributes to protect them from tampering. That means no more `permit` and
no more `attr_accessible`. It just works.

What this looks like:

``` erb
<%= signed_form_for(@user) do |f| %>
  <% f.add_signed_fields :zipcode, :state # Optionally add additional fields to sign %>

  <%= f.text_field :name %>
  <%= f.text_field :address %>
  <%= f.submit %>
<% end %>
```

``` ruby
UsersController < ApplicationController
  def create
    @user = User.find params[:id]
    @user.update_attributes params[:user]
  end
end
```

That's it. You're done. Need to add a field? Pop it in the form. You don't need to then update a list of attributes.
`signed_form_for` works just like the standard `form_for`.

Of course, you're free to continue using the standard `form_for`. `SignedForm` is strictly opt-in. It won't change the
way you use standard forms.

## Requirements

SignedForm requires:

* Ruby 1.9 or later
* Rails 4 or Rails 3.1+ ([strong_parameters](https://github.com/rails/strong_parameters) gem
  required for Rails 3)

## Installation

Add this line to your application's Gemfile:

    gem 'signed_form'

And then execute:

    $ bundle

If you're using Rails 3, you'll also need to install the [strong_parameters](https://github.com/rails/strong_parameters)
gem. Please set it up as instructed on the linked GitHub repo.

If you're using Rails 4, it works out of the box.

You'll need to include `SignedForm::ActionController::PermitSignedParams` in the controller(s) you want to use
SignedForm with. This can be done application wide by adding the `include` to your ApplicationController.

``` ruby
ApplicationController < ActionController::Base
  include SignedForm::ActionController::PermitSignedParams

  # ...
end
```

You'll also need to create an initializer:

    $ echo 'SignedForm::HMAC.secret_key = SecureRandom.hex(64)' > config/initializers/signed_form.rb

**IMPORTANT** Please read below for information regarding this secret key.

## Support for other Builders

* [SimpleForm Adapter](https://github.com/erichmenge/signed_form-simple_form)

## Special Considerations

If you're running only a single application server the above initializer should work great for you, with a couple of
caveats. If a user is in process of filling out a form and you restart your server, their form will be invalidated.
You could pick a secret key using `rake secret` and put that in the initializer instead, but then in the event you
remove a field someone could still access it using the old signature if some malicious person were to keep it around.

If you're running multiple application servers, the above initializer will not work. You'll need to keep the key in sync
between all the servers. The security caveat with that is that if you ever remove a field from a form without updating
that secret key, a malicious user could still access the field with the old signature. So you'll probably want to choose
a new secret in the event you remove access to an attribute in a form.

My above initializer example errs on the side of caution, generating a new secret key every time the app starts up. Only
you can decide what is right for you with respect to the secret key.

### Multiple Access Points

Take for example the case where you have an administrative backend. You might have `/admin/users/edit`. Users can also
change some information about themselves though, so there's `/users/edit` as well. Now you have an admin that gets
demoted, but still has a user account. If that admin were to retain a form signature from `/admin/users/edit` they could
use that signature to modify the same fields from `/users/edit`. As a means of preventing such access SignedForm provides
the `sign_destination` option to `signed_form_for`. Example:

``` erb
<%= signed_form_for(@user, sign_destination: true) do |f| %>
  <%= f.text_field :name %>
  <!-- ... -->
<% end %>
```

With `sign_destination` enabled, a form generated with a destination of `/admin/users/5` for example will only be
accepted at that end point. The form would not be accepted at `/users/5`. So in the event you would like to use
SignedForm on forms for the same resource, but different access levels, you have protection against the form being used
elsewhere.

### Caching

Another consideration to be aware of is caching. If you cache a form, and then change the secret key that form will
perpetually submit parameters that fail verification. So if you want to cache the form you should tie the cache key to
something that will be changed whenever the secret key changes.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
