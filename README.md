# PowerShell
This repo contains PowerShell scripts, snippets, and functions I talk about on [my blog](https://www.toddklindt.com/blog). Since I'll be updating these over time, they may differ slightly from the blog post they're from. 

Read them over before you run them, who knows what crazy things I've done in them. Most of the scripts here will need some tweaking before they run in your environment. If you have any questions leave an issue or send me a [tweet](https://twitter.com/toddklindt) and I'll see what I can do.

There are two modules, TKM365Commands.psm1 and TKOnPremCommands.psm1. To use them save the PSM1 file locally (or clone this repo), then run this command:
```PowerShell
Import-Module PathToFile\TKM365Commands.psm1 -verbose
```
Using the -verbose switch will list out the commands in the module. Alternately you can type this:
```PowerShell
Get-Command -Module TKM365Commands
```

If you have any suggestions open an issue and I'll check it out.

tk
