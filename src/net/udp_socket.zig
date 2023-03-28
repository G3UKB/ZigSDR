// udp_socket.zig
//
// Module - udp_socket
// Manage UDP socket instance
//
// Copyright (C) 2023 by G3UKB Bob Cowdery
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// The authors can be reached by email at:
//
// bob@bobcowdery.plus.com

const std = @import("std");
const net = struct {
    usingnamespace @import("network.zig");
};

const port_number = 10000;
var sock = undefined;

fn udp_open_bc_socket() void {

    // Create a UDP socket
    sock = try net.Socket.create(.ipv4, .udp);
    //defer sock.close();

    const incoming_endpoint = net.EndPoint{
        .address = net.Address{ .ipv4 = net.Address.IPv4.broadcast },
        .port = port_number,
    };

    sock.bind(incoming_endpoint) catch |err| {
        std.debug.print("failed to bind to {}:{}\n", .{ incoming_endpoint, err });
    };
}

pub fn udp_revert_socket() void {
    const _incoming_endpoint = net.EndPoint{
        .address = net.Address{ .ipv4 = net.Address.IPv4.any },
        .port = port_number,
    };
    _ = _incoming_endpoint;

    //self.sock2.set_read_timeout(Some(Duration::from_millis(100))).expect("set_read_timeout call failed");
    // Set buffer sizes?
    //self.sock2.set_recv_buffer_size(192000).expect("set_recv_buffer_size call failed");
    //println!("Receiver buffer sz {:?}", self.sock2.recv_buffer_size());
    //self.sock2.set_send_buffer_size(192000).expect("set_send_buffer_size call failed");
    //println!("Send buffer sz {:?}", self.sock2.send_buffer_size());
}

pub fn close_socket() void {
    sock.close();
}

pub fn udp_sock_ref() net.Socket {
    return sock;
}

//fn get_ip() String{
//    let iface = if_addrs::get_if_addrs().unwrap();
//    println!("My IP {}", iface[0].ip().to_string());
//    return iface[0].ip().to_string();
//}

