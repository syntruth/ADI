# A Net::LDAP::Filter object that doesn't do any filtering (outside of
# check that the CN attribute is present. This is used internally for
# specifying a 'no filter' condition for methods that require a filter
# object.
module ADI
  NIL_FILTER = Net::LDAP::Filter.pres('cn')
end
