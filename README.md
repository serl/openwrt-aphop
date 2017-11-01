# openwrt-aphop

Automatically have your OpenWRT device changing upstream AP to the best one.


## What?

Let's say your OpenWRT device is connected (also) as a wifi client, to a big network having multiple hotspots at different channels.

Let's assume you configured OpenWRT to be tied to one specific hotspot, but now you want it automatically switch to the best hotspot and keep working (if you have an AP on the same radio interface) even if no hotspot is around.

If so, `openwrt-aphop` is for you!


## Compatibility

It works for me in a Fonera2G, OpenWRT 15.05.1.
You may need to install a couple of packages, let me know which ones, in case...


## Configuration

Copy `config.example` to `config`, edit to suit your needs, comments inside should help you.

Run first `./find_best.sh` to check if meaningful results are shown.

Unleash the full power and run `./check.sh force`.
The optional parameter `[force]` will trigger a scan even if there is an active connection.

Note that when the hotspot is changed, the wifi is restarted, disconnecting all local clients.


## Cron

    52 5 * * * /path/to/aphop/check.sh force >/root/aphop/log_force 2>&1
    */10 * * * * /path/to/aphop/check.sh >/root/aphop/log 2>&1


## Blacklisting APs

You can optionally create a `blacklist` file, containing a mac address per line (uppercase and :).
