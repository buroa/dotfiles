function kubectl --wraps=kubectl
    if command -q kubecolor
        command kubecolor $argv
    else
        command kubectl $argv
    end
end
