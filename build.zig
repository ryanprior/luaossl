const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lua_dep = b.dependency("lua", .{
        .target = target,
        .release = optimize != .Debug,
    });
    const lua_lib = lua_dep.artifact(if (target.result.os.tag == .windows)
        "lua54"
    else
        "lua");

    const openssl_dep = b.dependency("openssl", .{
        .target = target,
        .optimize = optimize,
    });
    const openssl_lib = openssl_dep.artifact("openssl");

    const build_flags = &.{
        "-std=gnu99",
        "-fPIC",
        "-g",
        "-Wall",
        "-Wextra",
        "-Wno-missing-field-initializers",
        "-Wno-initializer-overrides",
        "-Wno-unused",
        "-Wno-dollar-in-identifier-extension",
        "-D_GNU_SOURCE",
        "-DLUA_COMPAT_APIINTCASTS",
    };
    const libluaossl = b.addLibrary(.{
        .name = "luaossl",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    libluaossl.root_module.addCSourceFile(.{
        .file = b.path("src/openssl.c"),
        .flags = build_flags,
    });
    libluaossl.root_module.linkLibrary(lua_lib);
    libluaossl.root_module.linkLibrary(openssl_lib);
    const install_lua = b.addInstallDirectory(.{
        .source_dir = b.path("src"),
        .install_dir = .prefix,
        .install_subdir = "share/lua/5.4/openssl",
        .include_extensions = &.{".lua"},
    });
    b.getInstallStep().dependOn(&install_lua.step);

    b.installArtifact(libluaossl);
}
