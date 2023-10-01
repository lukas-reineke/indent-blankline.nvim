-- This is filled out by hand based on what type treesitter reports
-- blank lines and/or lists of commands as in the given language

local M = {
    ada = {
    },
    bash = {
        program = true,
    },
    bass = {
    },
    bicep = {
    },
    bitbake = {
    },
    c = {
        translation_unit = true,
    },
    c_sharp = {
    },
    cairo = {
    },
    capnp = {
    },
    commonlisp = {
    },
    corn = {
    },
    cpon = {
    },
    cue = {
    },
    dart = {
    },
    devicetree = {
    },
    ecma = {
    },
    elixir = {
    },
    elsa = {
    },
    fennel = {
    },
    firrtl = {
    },
    fish = {
    },
    forth = {
    },
    fusion = {
    },
    gdscript = {
    },
    gleam = {
    },
    glimmer = {
    },
    go = {
    },
    godot_resource = {
    },
    hare = {
    },
    heex = {
    },
    haskell = {
        haskell = true,
        ERROR = true,
    },
    html = {
    },
    java = {
    },
    json = {
    },
    jsonnet = {
    },
    julia = {
    },
    kconfig = {
    },
    kdl = {
    },
    kotlin = {
    },
    lua = {
        chunk = true,
        block = true,
    },
    matlab = {
    },
    mlir = {
    },
    nix = {
    },
    ocaml = {
    },
    odin = {
    },
    pascal = {
    },
    php = {
    },
    pony = {
    },
    puppet = {
    },
    python = {
        module = true,
        block = true,
        string_content = true,
        string = true,
    },
    ql = {
    },
    query = {
    },
    r = {
    },
    rasi = {
    },
    re2c = {
    },
    ron = {
    },
    rst = {
    },
    ruby = {
    },
    rust = {
        source_file = true,
    },
    scala = {
    },
    smali = {
    },
    sparql = {
    },
    squirrel = {
    },
    starlark = {
    },
    supercollider = {
    },
    swift = {
    },
    systemtap = {
    },
    t32 = {
    },
    tablegen = {
    },
    teal = {
    },
    thrift = {
    },
    tiger = {
    },
    tlaplus = {
    },
    toml = {
    },
    turlte = {
    },
    ungrammar = {
    },
    usd = {
    },
    uxntal = {
    },
    v = {
    },
    verilog = {
    },
    vim = {
    },
    wing = {
    },
    yaml = {
    },
    yuck = {
    },
}

M.cpp = vim.tbl_extend("keep", M.c, {
})
M.arduion = M.cpp
M.cuda = M.cpp
M.astro = M.html
M.glsl = M.c
M.hjson = M.json
M.hlsl = M.cpp
M.ispc = vim.tbl_extend("keep", M.c, {
})
M.javascript = vim.tbl_extend("keep", M.ecma, {})
M.jsonc = M.json
M.luau = M.lua
M.nqc = M.c
M.objc = M.c
M.ocaml_interface = M.ocaml
M.tsx = vim.tbl_extend("keep", M.ecma, {})
M.typescript = M.ecma

return M
