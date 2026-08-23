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
     })

  ];
}