---
title: "How to get a JSON response with Selenium"
date: 2024-02-15
---

I recently started working on a hobby project, where I needed to get some data from a public website in an automated way.
Unfortunately the website was protected by a CAPTCHA, which is supposed to be passed manually by a real person. 
Perhaps there are ways to bypass it, but I really didn't want to go into that direction. 
That's why I decided to do it with [Selenium](https://www.selenium.dev/documentation/webdriver/).
I’ve already used it once before for hobby data scraping, so I knew it would do the job.

I implemented a script which would wait for the CAPTCHA to be passed manually, and then go on with the automated steps to get the data. 
The website was loading everything with AJAX requests, so I decided it would be easier to get the data directly from the JSON responses, 
instead of scraping it from the HTML page.

**Selenium with BrowserMob Proxy**

After a quick search for “selenium get json response”, I found several suggestions to use
[BrowserMob Proxy](https://github.com/lightbody/browsermob-proxy) and decided to give it a try.

The proxy allows you to record all network traffic between the browser and the server in the form of request/response entries. 
So you can click a button, scroll the page or whatever else triggers the AJAX request, then wait for the network traffic to stop 
and find the request/response entry of interest to get the JSON data.

For example, let's look at [https://resttesttest.com/](https://resttesttest.com/)
which is a nice, easy to use frontend for testing AJAX requests:

![Screenshot of resttesttest.com website](/assets/images/2024-02-15/rest_test_website.png)

Using Selenium with BrowserMob Proxy, we can click the “Ajax request” button and then get the JSON response from the proxy like this:

```java
var proxy = new BrowserMobProxyServer();
proxy.start();
System.out.println("Proxy started at port " + proxy.getPort());

var options = new ChromeOptions();
options.setProxy(ClientUtil.createSeleniumProxy(proxy));
var chrome = new ChromeDriver(options);
System.out.println("Chrome started");

proxy.enableHarCaptureTypes(CaptureType.REQUEST_CONTENT, CaptureType.RESPONSE_CONTENT);
proxy.newHar("test");

chrome.navigate().to("https://resttesttest.com/");
chrome.findElement(By.id("urlvalue")).clear();
chrome.findElement(By.id("urlvalue")).sendKeys("https://httpbin.org/json");
chrome.findElement(By.id("submitajax")).click();		
proxy.waitForQuiescence(1, 5, TimeUnit.SECONDS);

var entry = proxy.getHar().getLog().getEntries().stream()
    .filter((e) -> e.getRequest().getUrl().equals("https://httpbin.org/json"))
    .findFirst().get();

System.out.println(entry.getResponse().getContent().getText()); // prints the JSON response
```

Getting the JSON data directly is much better than having to scrape it from the HTML page.
How about executing the request directly instead of clicking a button?

One option would be to use the proxy to capture the HTTP headers and cookies after passing 
the CAPTCHA and use them in subsequent requests to the server. But why bother trying to 
recreate the HTTP context when we already have that in the Selenium browser? 

Turns out there is an easier way to do this - using Selenium's JavaScript executor 
we can execute the AJAX calls directly from the context of the web page.


**Using Selenium’s JavaScript executor**

The [JavascriptExecutor](https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/JavascriptExecutor.html)
interface allows you to execute JavaScript in the context of the currently loaded web page. 
With the [executeScript()](https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/JavascriptExecutor.html#executeScript(java.lang.String,java.lang.Object...))
and [executeAsyncScript()](https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/JavascriptExecutor.html#executeAsyncScript(java.lang.String,java.lang.Object...)) 
methods, you can pass a piece of JavaScript code as a string and even get a result back.
This means that we can simply construct a script that calls `fetch()` or uses an `XMLHttpRequest` to do the AJAX call, 
and then return the contents of the response body.

For example, to execute a simple GET request and get the JSON response:

```java
var driver = new ChromeDriver();
var jse = (JavascriptExecutor)driver;

driver.navigate().to("https://httpbin.org");

var script = """
    const url = arguments[0];
    const response = await fetch(url);
    const json = await response.json();
    return json;
""";

var response = (Map<?,?>)jse.executeScript(script, "/get");

System.out.println(response); // prints the JSON response, i.e. "{args={}, headers={...}, origin=YOUR_IP_ADDRESS, url=https://httpbin.org/get}"
```

Or to execute a POST request with parameters in the body:

```java
var driver = new ChromeDriver();
var jse = (JavascriptExecutor)driver;

driver.navigate().to("https://httpbin.org");

var script = """
    const url = arguments[0];
    const params = arguments[1];
    const options = { method: 'POST', body: JSON.stringify(params) };
    const response = await fetch(url, options);
    const json = await response.json();
    return json;
""";

var response = (Map<?,?>)jse.executeScript(script, "/post",
        Map.of("param1", "value1", "param2", "value2"));

System.out.println(response); // prints the JSON response, i.e. "{args={}, data={"param1":"value1","param2":"value2"}, ..., url=https://httpbin.org/post}"
```


You can view the full code examples here:
__[https://github.com/pmarinova/selenium-java-examples](https://github.com/pmarinova/selenium-java-examples)__