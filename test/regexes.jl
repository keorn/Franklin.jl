### ESC LINK
@testset "esclink" begin
    s = Markdown.htmlesc("[hello]")
    a,b,c = match(F.ESC_LINK_PAT, s).captures
    @test isnothing(a)
    @test b == "hello"
    @test isnothing(c)
    s = Markdown.htmlesc("[hello][]")
    a,b,c = match(F.ESC_LINK_PAT, s).captures
    @test isnothing(a)
    @test b == "hello"
    @test isempty(c)
    s = Markdown.htmlesc("[hello][id]")
    a,b,c = match(F.ESC_LINK_PAT, s).captures
    @test isnothing(a)
    @test b == "hello"
    @test c == "id"
    s = Markdown.htmlesc("![hello][id]")
    a,b,c = match(F.ESC_LINK_PAT, s).captures
    @test a == Markdown.htmlesc("!")
    @test b == "hello"
    @test c == "id"
    s = Markdown.htmlesc("[hello]:")
    @test isnothing(match(F.ESC_LINK_PAT, s))
end

### HBLOCK REGEXES

@testset "hb-if" begin
    for s in (
            "{{if var1}}",
            "{{if  var1 }}",
            "{{ if  var1 }}",
        )
        m = match(F.HBLOCK_IF_PAT, s)
        @test m.captures[1] == "var1"
    end
    for s in (
            "{{if var1 var2}}",
            "{{ifvar1}}"
        )
        m = match(F.HBLOCK_IF_PAT, s)
        @test isnothing(m)
    end
end
@testset "hb-else" begin
    for s in (
            "{{else}}",
            "{{ else}}",
            "{{  else   }}",
        )
        m = match(F.HBLOCK_ELSE_PAT, s)
        @test !isnothing(m)
    end
end
@testset "hb-elseif" begin
    for s in (
            "{{elseif var1}}",
            "{{else if  var1 }}",
            "{{ elseif  var1 }}",
        )
        m = match(F.HBLOCK_ELSEIF_PAT, s)
        @test m.captures[1] == "var1"
    end
    for s in (
            "{{else if var1 var2}}",
            "{{elif var1}}"
        )
        m = match(F.HBLOCK_ELSEIF_PAT, s)
        @test isnothing(m)
    end
end
@testset "hb-end" begin
    for s in (
            "{{end}}",
            "{{ end}}",
            "{{  end   }}",
        )
        m = match(F.HBLOCK_END_PAT, s)
        @test !isnothing(m)
    end
end
@testset "hb-isdef" begin
    for s in (
            "{{isdef var1}}",
            "{{ isdef  var1 }}",
            "{{ isdef  var1 }}",
            "{{ ifdef  var1 }}",
        )
        m = match(F.HBLOCK_ISDEF_PAT, s)
        @test m.captures[1] == "var1"
    end
    for s in (
            "{{isdef var1 var2}}",
            "{{is def var1}}",
            "{{if def var1}}"
        )
        m = match(F.HBLOCK_ISDEF_PAT, s)
        @test isnothing(m)
    end
end
@testset "hb-isndef" begin
    for s in (
            "{{isnotdef var1}}",
            "{{ isndef  var1 }}",
            "{{ ifndef  var1 }}",
            "{{ ifnotdef  var1 }}",
        )
        m = match(F.HBLOCK_ISNOTDEF_PAT, s)
        @test m.captures[1] == "var1"
    end
    for s in (
            "{{isnotdef var1 var2}}",
            "{{isnot def var1}}",
            "{{ifn def var1}}"
        )
        m = match(F.HBLOCK_ISNOTDEF_PAT, s)
        @test isnothing(m)
    end
end
@testset "hb-ispage" begin
    for s in (
            "{{ispage var1 var2}}",
        )
        m = match(F.HBLOCK_ISPAGE_PAT, s)
        @test m.captures[1] == "var1 var2"
    end
end
@testset "hb-isnotpage" begin
    for s in (
            "{{isnotpage var1 var2}}",
        )
        m = match(F.HBLOCK_ISNOTPAGE_PAT, s)
        @test m.captures[1] == "var1 var2"
    end
end
@testset "hb-for" begin
    for s in (
            "{{for (v1,v2,v3) in iterate}}",
            "{{for (v1, v2,v3) in iterate}}",
            "{{for ( v1, v2, v3) in iterate}}",
            "{{for ( v1  , v2 , v3 ) in iterate}}"
        )
        m = match(F.HBLOCK_FOR_PAT, s)
        @test isapproxstr(m.captures[1], "(v1, v2, v3)")
    end
    s = "{{for v1 in iterate}}"
    m = match(F.HBLOCK_FOR_PAT, s)
    @test isapproxstr(m.captures[1], "v1")

    # WARNING: NOT RECOMMENDED / NEEDS CARE
    s = "{{for v1,v2 in iterate}}"
    m = match(F.HBLOCK_FOR_PAT, s)
    @test isapproxstr(m.captures[1], "v1,v2")
    s = "{{for (v1,v2 in iterate}}"
    m = match(F.HBLOCK_FOR_PAT, s)
    @test isapproxstr(m.captures[1], "(v1,v2")
    s = "{{for v1,v2) in iterate}}"
    m = match(F.HBLOCK_FOR_PAT, s)
    @test isapproxstr(m.captures[1], "v1,v2)")
end
@testset "hb-toc" begin
    for s in (
            "{{toc}}",
            "{{ toc }}"
            )
        m = match(F.HBLOCK_TOC_PAT, s)
        @test !isnothing(m)
    end
end

# ========
# Checkers
# ========
@testset "ch-for" begin
    s = "{{for v in iterate}}"
    m = match(F.HBLOCK_FOR_PAT, s).captures[1]
    @test isnothing(F.check_for_pat(m))
    s = "{{for (v1,v2) in iterate}}"
    m = match(F.HBLOCK_FOR_PAT, s).captures[1]
    @test isnothing(F.check_for_pat(m))
    s = "{{for (v in iterate}}"
    m = match(F.HBLOCK_FOR_PAT, s).captures[1]
    @test_throws F.HTMLBlockError F.check_for_pat(m)
    s = "{{for v1,v2) in iterate}}"
    m = match(F.HBLOCK_FOR_PAT, s).captures[1]
    @test_throws F.HTMLBlockError F.check_for_pat(m)
    s = "{{for v1,v2 in iterate}}"
    m = match(F.HBLOCK_FOR_PAT, s).captures[1]
    @test_throws F.HTMLBlockError F.check_for_pat(m)
end
