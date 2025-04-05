{ pkgs, ... }:

# let
#   davinci-resolve = (pkgs.davinci-resolve.overrideAttrs (oldAttrs: {
#     buildFHSEnv = a: (oldAttrs.buildFHSEnv (a // {
#       extraBwrapArgs = a.extraBwrapArgs ++ [
#         "--bind /run/opengl-driver/etc/OpenCL /etc/OpenCL"
#       ];
#     }));
#   }));
# in

{
  home.packages = with pkgs; [
    davinci-resolve
    unstable.mlv-app
  ];
}
