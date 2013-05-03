## 0.2.0 (Unreleased)

* Move configuration options to main module name-space.
* Add default options hash to be passed to `signed_form_for`.
* Add a digestor to verify that out dated forms aren't being submitted.
* Add a test helper to make testing controllers easy.
* Only permit parameters but don't require them. Requiring them raises an exception if they're missing from the form
  submission. But in cases where other parameters are sent as well and the form object may be optional this would raise
  an exception that would be undesired.

## 0.1.2

* Fix issues where request method was not being compared properly and request
  url would not handle some potential cases leading to an erroneous rejection of
  the form. [Marc Schütz, #6]

## 0.1.1

* Add some select and date/time field helpers that were not getting added to the signature [#5].

## 0.1.0

* Add `sign_destination` option to `signed_form_for`.

## 0.0.1

* Initial Release
