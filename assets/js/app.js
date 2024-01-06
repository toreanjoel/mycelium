// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// Connect to other sockets
let socket = new Socket("/socket/2aa5bfbf-b5f5-4eef-9ffa-6cb88448579c", {
  params: { token: window.userToken },
});
socket.connect();

let lobbyChannel = socket.channel("lobby", {});
lobbyChannel.join()
  .receive("ok", (resp) => {
    console.log("resp", resp)
    // we send get and send if we are joined.
    const pingElm = document.querySelector("#elm-ping");
    const shoutElm = document.querySelector("#elm-shout");
    const dcElm = document.querySelector("#elm-dc");

    // interact with the elements to push events
    pingElm.addEventListener("click", () => {
      console.log("ping the server")
      lobbyChannel.push("ping", {})
    })

    shoutElm.addEventListener("click", () => {
      console.log("shout to the server")
      lobbyChannel.push("shout", {})
    })
    
    dcElm.addEventListener("click", () => {
      console.log("disconnect from the server")
      lobbyChannel.push("disconnect", { channel: "lobby"})
    })
  
  })
  .receive("error", (resp) => {
    console.log("Unable to join", resp);
  });

let chatChannel = socket.channel("chat", {});
chatChannel.join()
  .receive("ok", (resp) => {
    console.log("resp", resp)
  })
  .receive("error", (resp) => {
    console.log("Unable to join", resp);
  });
let gameChannel = socket.channel("game", {});
gameChannel.join()
  .receive("ok", (resp) => {
    console.log("resp", resp)
  })
  .receive("error", (resp) => {
    console.log("Unable to join", resp);
  });

