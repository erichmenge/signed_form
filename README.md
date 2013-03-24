# SignedForm [![Build Status](https://travis-ci.org/erichmenge/signed_form.png?branch=master)](https://travis-ci.org/erichmenge/signed_form)

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
UserController < ApplicationController
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

## Alpha Quality Software

Because of the security sensitive nature of this gem I'm releasing this as 0.0.1.pre1 until I can get some more eyes on
the code. This software should not be considered production ready. At this time it is only suitable for experimentation.

Now that I've made that disclaimer, you should know that SignedForm is functional.

## Requirements

SignedForm requires:

* Ruby 1.9 or later
* Ruby on Rails 4 or 3 ([strong_parameters](https://github.com/rails/strong_parameters) gem required for Rails 3)

## Installation

Add this line to your application's Gemfile:

    gem 'signed_form', '0.0.1.pre1'

And then execute:

    $ bundle

If you're using Rails 3, you'll also need to install the [strong_parameters](https://github.com/rails/strong_parameters)
gem. Please set it up as instructed on the linked GitHub repo.

If you're using Rails 4, it works out of the box.

You'll also need to create an initializer:

    $ echo 'SignedForm::HMAC.secret_key = SecureRandom.hex(64)' > config/initializers/signed_form.rb

**IMPORTANT** Please read below for information regarding this secret key.

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
