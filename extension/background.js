const NATIVE_HOST = "com.urlhist.host";
const SKIP_SCHEMES = ["chrome://", "chrome-extension://", "about:", "edge://", "data:"];

function shouldSkip(url) {
  return SKIP_SCHEMES.some(scheme => url.startsWith(scheme));
}

chrome.tabs.onUpdated.addListener((_tabId, changeInfo, tab) => {
  if (changeInfo.status !== "complete") return;

  const url = changeInfo.url || tab.url;
  if (!url || shouldSkip(url)) return;

  const timestamp = new Date().toISOString().replace("T", " ").substring(0, 19);
  const title = tab.title || "";

  chrome.runtime.sendNativeMessage(
    NATIVE_HOST,
    { url, timestamp, title },
    (_response) => {
      if (chrome.runtime.lastError) {
        console.log("Native host error:", chrome.runtime.lastError.message);
        
      }
    }
  );
});
