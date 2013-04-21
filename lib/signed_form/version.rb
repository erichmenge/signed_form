module SignedForm
  MAJOR = 0
  MINOR = 1
  PATCH = 2
  PRE   = nil

  VERSION = [MAJOR, MINOR, PATCH, PRE].compact.join '.'
end
