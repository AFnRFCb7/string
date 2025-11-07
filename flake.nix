{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { visitor } :
                        let
                            implementation =
                                { template , values } :
                                    let
                                        string-values =
                                            let
                                                mapper =
                                                    name : value :
                                                        visitor
                                                            {
                                                                boolean = path : value : if value then "true" else "false" ;
                                                                int = path : value : builtins.toString value ;
                                                                float = path : value : builtins.toString value ;
                                                                lambda = path : value : builtins.throw "We can not string ${ builtins.toJSON path } because it is a lambda and not stringable" ;
                                                                list = path : value : builtins.throw "We can not string ${ builtins.toJSON path } because it is a list and not stringable" ;
                                                                null = path : value : "null" ;
                                                                path = path : value : builtins.toString path ;
                                                                set = path : value : if builtins.hasAttr "__toString" value then builtins.getAttr "__toString" value else "We can not string ${ builtins.toJSON path } because it is a set (and has no __toString attribute) and not stringable" ;
                                                                string = path : value : value ;
                                                            }
                                                            value ;
                                                in builtins.mapAttrs mapper values ;
                                        template-value =
                                            let
                                                blank = builtins.mapAttrs mapper values ;
                                                mapper = name : value : "" ;
                                                in if builtins.typeOf template blank == "string" then template string-values else builtins.throw "template is not stringable but instead is a ${ builtins.typeOf ( template blank ) }" ;
                                        in template-value ;
                            in
                                {
                                    check =
                                        {
                                            coreutils ,
                                            mkDerivation ,
                                            success ? false ,
                                            template ,
                                            value ? false ,
                                            values ,
                                            writeShellApplication
                                        } :
                                            mkDerivation
                                                {
                                                    installPhase = ''execute-test "$out"'' ;
                                                    name = "check" ;
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "execute-test" ;
                                                                        runtimeInputs = [ coreutils ] ;
                                                                        text =
                                                                            let
                                                                                expected = { success = success ; value = value ; } ;
                                                                                observed = builtins.tryEval ( implementation { template = template ; values = values ; } ) ;
                                                                                in
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        touch "$OUT"
                                                                                        ${ if expected.success && observed.success && builtins.typeOf expected.value == "string" && builtins.typeOf observed.value == "string" && expected.value != observed.value then ''failure 2b2e88f8 "We expected the value to be ${ expected.value } but we observed ${ observed.value }"'' else "#" }
                                                                                        ${ if expected.success && builtins.typeOf expected.value != "string" then ''failure 4e462b55 "We expected the expected value to be a string but it was a ${ builtins.typeOf expected.value }"'' else "#" }
                                                                                        ${ if observed.success && builtins.typeOf observed.value != "string" then ''failure b9f3746c "We expected the observed value to be a string but it was a ${ builtins.typeOf observed.value }"'' else "#" }
                                                                                        ${ if ! expected.success && expected.value != false then ''failure bbab23ec "We expected the expected value to be false but it was a ${ builtins.typeOf expected.value }"'' else "#" }
                                                                                        ${ if ! observed.success && observed.value != false then ''failure d9309d66 "We expected the observed value to be false but it was a ${ builtins.typeOf observed.value }"'' else "#" }
                                                                                        ${ if expected.success && expected.success != observed.success then ''failure 85327aee "We expected success but we observed failure"'' else "#" }
                                                                                        ${ if ! expected.success && expected.success != observed.success then ''failure 5b98fa47 "We expected failure and we observed success"'' else "#" }
                                                                                    '' ;
                                                                    }
                                                            )
                                                        ] ;
                                                    src = ./. ;
                                                } ;
                                    implementation = implementation ;
                                } ;
            } ;
}