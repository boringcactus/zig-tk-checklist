const std = @import("std");

fn add_sources(allocator: *std.mem.Allocator, objs: []const u8, subdir: []const u8, exe: *std.build.LibExeObjStep) void {
    var iter = std.mem.tokenize(objs, " \n");
    while (iter.next()) |arg| {
        var renamed = allocator.dupe(u8, arg) catch |err| std.debug.panic("bruh {}", .{err});
        renamed[std.mem.len(renamed) - 1] = 'c';
        const path = std.fmt.allocPrint(
            allocator,
            "./tcl/{s}/{s}",
            .{subdir, renamed}
        ) catch |err| std.debug.panic("bruh {}", .{err});
        defer allocator.free(path);
        exe.addCSourceFile(path, &.{
            "-Duint64_t=unsigned long long", // apparently we don't. have that? somehow?
            "-w", // warnings are cringe
            "-DCFG_RUNTIME_LIBDIR=\"\"", // hold my beer
            "-DCFG_RUNTIME_BINDIR=\"\"", // this will probably break things
            "-DCFG_RUNTIME_SCRDIR=\"\"", // like a lot of things
            "-DCFG_RUNTIME_INCDIR=\"\"", // so many things
            "-DCFG_RUNTIME_DOCDIR=\"\"", // but maybe it won't
            "-DCFG_INSTALL_LIBDIR=\"\"",
            "-DCFG_INSTALL_BINDIR=\"\"",
            "-DCFG_INSTALL_SCRDIR=\"\"",
            "-DCFG_INSTALL_INCDIR=\"\"",
            "-DCFG_INSTALL_DOCDIR=\"\""
        });
    }
}

pub fn build(b: *std.build.Builder) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig-tk-checklist", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    exe.linkLibC();

    // TCL
    // ---

    // generic
    exe.addIncludeDir("./tcl/generic");
    const generic_objs =
        \\ regcomp.o regexec.o regfree.o regerror.o tclAlloc.o
        \\ tclAssembly.o tclAsync.o tclBasic.o tclBinary.o tclCkalloc.o
        \\ tclClock.o tclCmdAH.o tclCmdIL.o tclCmdMZ.o
        \\ tclCompCmds.o tclCompCmdsGR.o tclCompCmdsSZ.o tclCompExpr.o
        \\ tclCompile.o tclConfig.o tclDate.o tclDictObj.o tclDisassemble.o
        \\ tclEncoding.o tclEnsemble.o
        \\ tclEnv.o tclEvent.o tclExecute.o tclFCmd.o tclFileName.o tclGet.o
        \\ tclHash.o tclHistory.o tclIndexObj.o tclInterp.o tclIO.o tclIOCmd.o
        \\ tclIORChan.o tclIORTrans.o tclIOGT.o tclIOSock.o tclIOUtil.o
        \\ tclLink.o tclListObj.o
        \\ tclLiteral.o tclLoad.o tclMain.o tclNamesp.o tclNotify.o
        \\ tclObj.o tclOptimize.o tclPanic.o tclParse.o tclPathObj.o tclPipe.o
        \\ tclPkg.o tclPkgConfig.o tclPosixStr.o
        \\ tclPreserve.o tclProc.o tclRegexp.o
        \\ tclResolve.o tclResult.o tclScan.o tclStringObj.o
        \\ tclStrToD.o tclThread.o
        \\ tclThreadAlloc.o tclThreadJoin.o tclThreadStorage.o tclStubInit.o
        \\ tclTimer.o tclTrace.o tclUtf.o tclUtil.o tclVar.o tclZlib.o
        \\ tclTomMathInterface.o
    ;
    add_sources(allocator, generic_objs, "generic", exe);

    // windows
    exe.addIncludeDir("./tcl/win");
    const windows_objs =
        \\ tclWin32Dll.o
        \\ tclWinChan.o
        \\ tclWinConsole.o
        \\ tclWinError.o
        \\ tclWinFCmd.o
        \\ tclWinFile.o
        \\ tclWinInit.o
        \\ tclWinLoad.o
        \\ tclWinNotify.o
        \\ tclWinPipe.o
        \\ tclWinSerial.o
        \\ tclWinSock.o
        \\ tclWinThrd.o
        \\ tclWinTime.o
        \\ tclWinReg.o
        \\ tclWinDde.o
    ;
    add_sources(allocator, windows_objs, "win", exe);

    // tommath
    exe.addIncludeDir("./tcl/libtommath");
    const tommath_objs =
        \\ bn_s_mp_reverse.o bn_s_mp_mul_digs_fast.o
        \\ bn_s_mp_sqr_fast.o bn_mp_add.o bn_mp_and.o
        \\ bn_mp_add_d.o bn_mp_clamp.o bn_mp_clear.o bn_mp_clear_multi.o
        \\ bn_mp_cmp.o bn_mp_cmp_d.o bn_mp_cmp_mag.o
        \\ bn_mp_cnt_lsb.o bn_mp_copy.o
        \\ bn_mp_count_bits.o bn_mp_div.o bn_mp_div_d.o bn_mp_div_2.o
        \\ bn_mp_div_2d.o bn_mp_div_3.o bn_mp_exch.o bn_mp_expt_u32.o
        \\ bn_mp_grow.o bn_mp_init.o
        \\ bn_mp_init_copy.o bn_mp_init_multi.o bn_mp_init_set.o
        \\ bn_mp_init_size.o bn_s_mp_karatsuba_mul.o
        \\ bn_s_mp_karatsuba_sqr.o bn_s_mp_balance_mul.o
        \\ bn_mp_lshd.o bn_mp_mod.o bn_mp_mod_2d.o bn_mp_mul.o bn_mp_mul_2.o
        \\ bn_mp_mul_2d.o bn_mp_mul_d.o bn_mp_neg.o bn_mp_or.o
        \\ bn_mp_radix_size.o bn_mp_radix_smap.o
        \\ bn_mp_read_radix.o bn_mp_rshd.o bn_mp_set.o
        \\ bn_mp_shrink.o
        \\ bn_mp_sqr.o bn_mp_sqrt.o bn_mp_sub.o bn_mp_sub_d.o
        \\ bn_mp_signed_rsh.o
        \\ bn_mp_to_ubin.o
        \\ bn_s_mp_toom_mul.o bn_s_mp_toom_sqr.o bn_mp_to_radix.o
        \\ bn_mp_ubin_size.o bn_mp_xor.o bn_mp_zero.o bn_s_mp_add.o
        \\ bn_s_mp_mul_digs.o bn_s_mp_sqr.o bn_s_mp_sub.o
    ;
    add_sources(allocator, tommath_objs, "libtommath", exe);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
