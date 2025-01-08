if dotpickles_role "home"
  set -gx GIT_DUET_CO_AUTHORED_BY true
  # need to use me first for commit signing
  set -gx GIT_DUET_ROTATE_AUTHOR false
end
