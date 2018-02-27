## 0.5.0
This release is owed entirely to [@eric1234][] & [@schuetzm][], thank you both  
for your efforts and patience.

In short, this release is intended to bring the project back to an active state,  
any mistakes having been added in this version should be regarded as  
intentional. Let's move forward.  

Thank you as well to our gracious host [@erichmenge][] for incepting this gem of  
a gem.

* Merged #25 - Fix tests  
  Contributed by Marc Schütz <schuetzm@gmx.net>

* Merged #29 - Use `prepend_before_action` if available  
  Contributed by Marc Schütz <schuetzm@gmx.net>

* Merged #31 - Release attempt  
  Contributed by Eric Anderson <eric@pixelwareinc.com>

* Temporarily removed fields helper from being tested in 8517af8  
  Contributed by Eric Anderson <eric@pixelwareinc.com>

* Remove deprecation warnings & fixed bug revealed in 9985314  
  Contributed by Eric Anderson <eric@pixelwareinc.com>

* Enable signed_form to be tested against more versions of rails in b263e5b  
  Contributed by Eric Anderson <eric@pixelwareinc.com>

Released by Johnneylee Jack Rollins <Johnneylee.Rollins@gmail.com>

[@eric1234]:   https://github.com/eric1234  
[@schuetzm]:   https://github.com/schuetzm  
[@erichmenge]: https://github.com/erichmenge  

## 0.4.0
* Designate fields that submit multiple values correctly  
  Contributed by Marc Schütz <schuetzm@gmx.net>

* Allow to provide blocks to form helper methods  
   Previously, the block was swallowed rather than passed to the form helper.  
   Christopher Schramm <cschramm@shakaweb.org>

## 0.3.0

* Disabled fields are no longer signed by default.  
  To include a disabled field, explicitly sign it with  
  `f.add_signed_fields field_name`  
  Contributed by James Moriarty <jamespaulmoriarty@gmail.com>

* Fix multiple fields_for calls  
  Prior to this fix, only the last of the calls would be passed.  
  Contributed by Marc Schütz <schuetzm@gmx.net>

* ActiveAdmin integration  
  CSchramm has created a plugin that integrates both activeadmin and signed_form  
  Contributed by Christopher Schramm <cschramm@shakaweb.org>

* Tests pass under Rails 4.1  
  Contributed by Christopher Schramm <cschramm@shakaweb.org>

## 0.2.0

* Instead of using `signed_form_for` add an option for form signing to  
  `form_for` so that signing third party builders like SimpleForm doesn't  
  require an adapter.

* Move configuration options to main module name-space.

* Add default options hash to be passed to `form_for`.

* Add a digestor to verify that out dated forms aren't being submitted.

* Add a test helper to make testing controllers easy.

* Only permit parameters but don't require them.  
  Requiring them raises an exception if they're missing from the form  
  submission. But in cases where other parameters are sent as well and the form  
  object may be optional this would raise an exception that would be undesired.

* Allow all forms to be signed by default.

## 0.1.2

* Fix issues where request method was not being compared properly and request  
  url would not handle some potential cases leading to an erroneous rejection  
  of the form. [Marc Schütz, #6]

## 0.1.1

* Add some select and date/time field helpers that were not getting added to  
  the signature [#5].

## 0.1.0

* Add `sign_destination` option to `signed_form_for`.

## 0.0.1

* Initial Release

