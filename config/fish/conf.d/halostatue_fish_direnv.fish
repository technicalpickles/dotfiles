if not functions -q __direnv_export_eval; and command -sq direnv
    direnv hook fish | source
end

function _halostatue_fish_direnv_uninstall -e halostatue_fish_direnv_uninstall
    functions -e (functions -a | command awk '/^__direnv/') (status function)
end
