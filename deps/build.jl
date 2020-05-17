using BinDeps

@BinDeps.setup

path = dirname(@__FILE__)

libbouknap = library_dependency("libbouknap")
libminknap = library_dependency("libminknap")

pisinger_webpage_uri = "http://hjemmesider.diku.dk/~pisinger"

pisinger_files_root = joinpath(path, "..", "libpisinger")
lib_pisinger_root = joinpath(path, "libpisinger")
lib_pisinger_minknap= joinpath(lib_pisinger_root, "minknap")
lib_minknap_build = joinpath(lib_pisinger_minknap, "build")
lib_pisinger_bouknap = joinpath(lib_pisinger_root, "bouknap")
lib_bouknap_build = joinpath(lib_pisinger_bouknap, "build")

if Sys.iswindows()
    using WinRPM
    WinRPM.install("gcc", yes=true)
    GCCROOT = joinpath(Pkg.dir("WinRPM"), "deps")


	makedeplnk = "https://sourceforge.net/projects/gnuwin32/files/make/3.81/make-3.81-dep.zip/download"
	makebinlnk = "https://sourceforge.net/projects/gnuwin32/files/make/3.81/make-3.81-bin.zip/download"

	makedepzip 	= joinpath(pisinger_files_root, "make-3.81-dep.zip")
	makebinzip   = joinpath(pisinger_files_root, "make-3.81-bin.zip")
	makebuilddir = joinpath(pisinger_files_root,  "make")

    make = joinpath(makebuilddir, "bin", "make.exe")
    icnv = joinpath(makebuilddir, "bin", "libiconv2.dll"),
	intl = joinpath(makebuilddir, "bin", "libintl3.dll"),
       
    provides(SimpleBuild,
    (@build_steps begin
        FileDownloader(makedeplnk, makedepzip)
        FileDownloader(makebinlnk, makebinzip)
        FileUnpacker(makedepzip, makebuilddir, joinpath("bin", "libiconv2.dll"))
        FileUnpacker(makebinzip, makebuilddir, joinpath("bin", "make.exe"))
        FileDownloader("$pisinger_webpage_uri/bouknap.c", joinpath(lib_pisinger_bouknap, "bouknap.c"))
        CreateDirectory(lib_bouknap_build)
        @build_steps begin
            ChangeDirectory(lib_bouknap_build)
            `cmake ..`
            `$make`
        end
    end), libbouknap, os=:Windows)

    provides(SimpleBuild,
        (@build_steps begin
            FileDownloader("$pisinger_webpage_uri/minknap.c", joinpath(lib_pisinger_minknap, "minknap.c"))
            CreateDirectory(lib_minknap_build)
            @build_steps begin
                ChangeDirectory(lib_minknap_build)
                `cmake ..`
                `$make`
                MakeTargets()
            end
        end), libminknap, os=:Windows)
else
    provides(SimpleBuild,
        (@build_steps begin
            FileDownloader("$pisinger_webpage_uri/bouknap.c", joinpath(lib_pisinger_bouknap, "bouknap.c"))
            if Sys.isapple() # Removing deprecated headers for osx
                @build_steps begin
                    `sed -i '' '/values\.h/d' $lib_pisinger_bouknap/bouknap.c`
                    `sed -i '' '/malloc\.h/d' $lib_pisinger_bouknap/bouknap.c`
                end
            end
            CreateDirectory(lib_bouknap_build)
            @build_steps begin
                ChangeDirectory(lib_bouknap_build)
                `cmake ..`
                MakeTargets()
            end
        end), libbouknap, installed_libpath = lib_bouknap_build)

    provides(SimpleBuild,
        (@build_steps begin
            FileDownloader("$pisinger_webpage_uri/minknap.c", joinpath(lib_pisinger_minknap, "minknap.c"))
            if Sys.isapple() # Removing deprecated headers for osx
                @build_steps begin
                    `sed -i '' '/values\.h/d' $lib_pisinger_minknap/minknap.c`
                    `sed -i '' '/malloc\.h/d' $lib_pisinger_minknap/minknap.c`
                end
            end
            CreateDirectory(lib_minknap_build)
            @build_steps begin
                ChangeDirectory(lib_minknap_build)
                `cmake ..`
                MakeTargets()
            end
        end), libminknap, installed_libpath = lib_minknap_build)
end

Sys.iswindows() && push!(BinDeps.defaults, BuildProcess)

@BinDeps.install Dict(:libbouknap => :_jl_libbouknap,
                      :libminknap => :_jl_libminknap)

Sys.iswindows() && pop!(BinDeps.defaults)