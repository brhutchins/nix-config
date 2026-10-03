{ inputs, ... }: {
  nixpkgs.overlays = [
     (self: super: {
       karabiner-elements = super.karabiner-elements.overrideAttrs (old: {
         version = "14.13.0";
         src = super.fetchurl {
           inherit (old.src) url;
           hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
         };
       });

        poppler = super.poppler.overrideAttrs (old: {
          version = "26.08.0";
          src = super.fetchurl {
            url = "https://poppler.freedesktop.org/poppler-26.08.0.tar.xz";
            hash = "sha256-3JBuaM6mmBCXBqxqo9LJ1FEvz8rELZC4r82khtG5q9A=";

          };
        });

        vimPlugins = super.vimPlugins // {
          copilot-lua = super.vimPlugins.copilot-lua.overrideAttrs (_: {
            src = self.fetchFromGitHub {
              owner = "zbirenbaum";
              repo = "copilot.lua";
              rev = "b1482409cefe8b201f89122c682189fabf0436da";
              hash = "sha256-05f76OeWBlFmlUh90tH4XMMKfNI1jnhuIJDqYPPQokA=";
            };
          });
        };
      })

  ];
}
