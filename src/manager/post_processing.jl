const JD_PY_MIN_NAME = ".__py_tmp_minscript.py"

"""
    optimize(; prerender, minify)

Does a full pass followed by a pre-rendering and minification step.

* `prerender=true`: whether to pre-render katex and highlight.js (requires `node.js`)
* `minify=true`:    whether to minify output (requires `python3` and `css_html_js_minify`)
"""
function optimize(; prerender::Bool=true, minify::Bool=true)
    #
    # Prerendering
    #
    if prerender && !JD_CAN_PRERENDER
        @warn "I couldn't find node and so will not be able to pre-render javascript."
        prerender = false
    end
    if prerender && !JD_CAN_HIGHLIGHT
        @warn "I couldn't load 'highlight.js' so will not be able to pre-render code blocks. " *
              "You can install it with `npm install highlight.js`."
    end
    # re-do a (silent) full pass
    start = time()
    print("→ Full pass")
    withpre = ifelse(prerender, rpad(" with pre-rendering... ", 24), rpad("", 24))
    print(withpre)
    succ = (serve(single=true, prerender=prerender) == 0)
    time_it_took(start)

    #
    # Minification
    #
    if minify && succ
        if JD_CAN_MINIFY
            start = time()
            print(rpad("→ Minifying *.[html|css] files...", 35))
            # copy the script to the current dir
            cp(joinpath(dirname(pathof(JuDoc)), "scripts", "minify.py"), JD_PY_MIN_NAME; force=true)
            # run it
            succ = success(`bash -c "python3 $JD_PY_MIN_NAME > /dev/null"`)
            # remove the script file
            rm(JD_PY_MIN_NAME)
            time_it_took(start)
        else
            @warn "I didn't find css_html_js_minify, you can install it via pip the output will "*
                  "not be minified."
        end
    end
    return succ
end


"""
    publish(; minify=true, prerender=true)

This is a simple wrapper doing a git commit and git push without much fanciness. It assumes the
current directory is a git folder.
This will work in most simple scenarios (e.g. there's only one person updating the website).
In other scenarios you should probably do this manually.

Keyword arguments

* `prerender=true`: prerender javascript before pushing see [`optimize`](@ref)
* `minify=true`:    minify output before pushing see [`optimize`](@ref)
* `nopass=false`:   set this to true if you have already run `optimize` manually.
"""
function publish(; prerender::Bool=true, minify::Bool=true, nopass::Bool=false)
    succ = true
    nopass || (succ = optimize(prerender=prerender, minify=minify))
    if succ
        time = start()
        print(rpad("→ Pushing updates with git...", 35))
        try
            run(`bash -c "git add -A && git commit -m \"jd-update\" --quiet && git push --quiet"`,
                wait=true)
            time_it_took(start)
        catch e
            println("✘ Could not push updates, verify your connection and try manually.\n")
            @show e
        end
    else
        println("✘ Something went wrong in the optimisation step. Not pushing updates.")
    end
end


"""
    cleanpull()

Cleanpull allows you to pull from your remote git repository after having removed the local
output directory. This will help avoid merge clashes.
"""
function cleanpull()
    JD_FOLDER_PATH[] = pwd()
    set_paths!()
    if isdir(JD_PATHS[:out])
        print("Removing local output dir...")
        rm(JD_PATHS[:out], force=true, recursive=true)
        println(" [done] ✔")
    end
    try
        print("Retrieving updates from GitHub...")
        run(`bash -c "git pull --quiet"`, wait=true)
        println(" [done] ✔")
    catch e
        println("Could not pull updates from Github, verify your connection and try manually.\n")
    end
end