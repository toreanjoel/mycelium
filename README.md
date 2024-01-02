# wsserve
TCP Client Server written in Elixir and Phoenix

## Overview

WSServer is an MVP real-time server platform designed to facilitate the rapid development and deployment of interactive applications. Leveraging Elixir and the Phoenix Framework, WSServer provides the backbone for a variety of real-time functionalities, from live chat systems to dynamic game servers using the TCP protocol (initially).

## Application Description

At its core, WSServer is built to handle real-time WebSocket connections with ease, allowing users to create and manage server instances that can cater to their specific real-time interaction needs. Whether it's for turn-based strategy games or synchronous collaborative tools, WSServer offers a robust and scalable solution.

### Features

- **WebSocket-Based Communication**: Implements Phoenix Channels for efficient, bidirectional messaging.
- **Dynamic Server Management**: Utilizes a Dynamic Supervisor to manage the lifecycle of real-time server instances.
- **Modular Design**: Supports a range of applications by allowing for custom server logic to be plugged into the core system.
- **Simplified MVP Approach**: The initial release focuses on core functionalities, omitting user authentication and message persistence to streamline development and focus on essential real-time interactions.

### Architecture Highlights

- **Supervisory Structure**: Leverages Elixir's OTP for fault tolerance and self-healing capabilities.
- **Server Process Isolation**: Each server instance operates in isolation, enhancing security and stability.
- **Real-Time Data Flow**: Ensures rapid data exchange and state updates across client-server connections.

## Implementation Details

### Server Process Creation

Users can create server processes that are automatically supervised and managed by the platform. These processes handle individual WebSocket connections and facilitate real-time communication between connected clients.

### Stateless MVP Model

In its MVP phase, WSServer operates without persistent storage of messages or user sessions, focusing on live interactions. This decision streamlines the initial offering and ensures a focus on performance and reliability.

### Future Considerations

- **Authentication**: Plans are in place to integrate JWT-based authentication, allowing for secure connections and controlled access to server instances.
- **Persistence**: Subsequent versions will incorporate message and state persistence, providing a history of interactions for clients that connect later.

## Usage

### Creating a Server Instance

Users can initialize a server instance through a simple API, specifying the type and configuration needed for their application.

### Connecting Clients

Clients can connect to a server instance via a WebSocket URL, formatted as `/socket/:id`, where `:id` is the unique identifier for the server instance.

## Documentation

Comprehensive documentation will be provided, detailing setup procedures, API usage, and example applications. This documentation will evolve alongside the platform, ensuring it remains an up-to-date resource for developers.

## Load Testing and Performance

Prior to release, WSServer will undergo rigorous load testing to ensure it can handle the expected concurrent connection load and message throughput. Performance metrics and results will be made available in the documentation.

## Contributing

As an open platform, contributions and feedback are welcomed. Developers are encouraged to submit issues, pull requests, or suggestions to help improve WSServer.

---

Updates around detailed analysis on server performance, load testing, and implementation testing with documentation on uses and usecases will have updates be added to the repo in the near future.

