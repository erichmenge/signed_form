## 0.2.0 (Unreleased)

* Move configuration options to main module name-space.
* Add default options hash to be passed to `signed_form_for`.

## 0.1.2

* Fix issues where request method was not being compared properly and request
  url would not handle some potential cases leading to an erronous rejection of
  the form. [Marc Schütz, #6]

## 0.1.1

* Add some select and date/time field helpers that were not getting added to the signature [#5].

## 0.1.0

* Add `sign_destination` option to `signed_form_for`.

## 0.0.1

* Initial Release
