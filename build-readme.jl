using Weave
if false
    using Pkg
    cd("c:/git/Game2048/")
    Pkg.activate("./weave-env")
end

weave("README.jmd", out_path=:pwd, doctype="github")