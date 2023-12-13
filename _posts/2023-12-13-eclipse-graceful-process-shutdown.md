---
title: "Eclipse graceful process shutdown "
date: 2023-12-13
---

The Eclipse IDE might look outdated and clunky, but it has always been my choice for Java development.
It's probably because I've used it more than any other IDE and feel it comfortable, compared to the 
more modern alternatives such as IntelliJ IDEA.

Recently I stumbled upon an annoying issue which is not new for Eclipse - 
[Java shutdown hooks are not executed](https://bugs.eclipse.org/bugs/show_bug.cgi?id=38016) when a debug launch is terminated, 
e.g. when you click the red stop button on the toolbar. This becomes a problem when you need to debug the shutdown 
hook itself or if the shutdown hook needs to do some cleanup, save some program state, etc.

In my case the shutdown hook was responsible for deregistering an mDNS-SD service and I needed a clean shutdown where the service 
was properly removed. Terminating the process abruptly would leave the service registration lingering until a certain timeout and 
other applications on the network would still see it.

I found this [third-party Eclipse plugin](https://marketplace.eclipse.org/content/yet-another-terminate-button-yatb), 
but it didn't solve my problem as it was only for Linux. It turns out it's not straightforward to kill a process gracefully on Windows...

The issue was bugging me so I decided to implement my own "clean shutdown" button:
* The "Shutdown" button should appear next to the standard "Terminate" button on the toolbar, console view, etc.
* The button should execute a platform specific command to terminate the process gracefully, i.e. `kill -SIGINT <process_id>` on Linux
* The "shutdown command" should be configurable from preferences

Having a configurable shutdown command allows me to use a Windows specific tool such as [windows-kill](https://github.com/ElyDotDev/windows-kill) 
to send a SIGINT to the process. The shutdown command is a simple text field preference, which is evaluated and executed when the "Shutdown" button is clicked.

![Screenshot of shutdown button preferences.](https://raw.githubusercontent.com/pmarinova/eclipse-shutdown-button/v1.0.0/screenshots/shutdown_button_prefs.png)

The `${pid}` variable is substituted with the id of the currently selected process in the Debug view. (Note: All debugging commands in Eclipse such as Resume, 
Suspend, Terminate, etc., work on the active selection in the Debug view. This is why the Debug view must be open while debugging as it provides the context 
for all of the debug functionalities - views, commands, etc.)

The process id is available via the IProcess debug core API since __version 4.23 (2022-03)__ of the Eclipse Platform, 
so this is the __minimum Eclipse version__ supported by the shutdown button plugin.

__[https://github.com/pmarinova/eclipse-shutdown-button](https://github.com/pmarinova/eclipse-shutdown-button)__