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
var sock: net.Socket = undefined;

pub fn udp_open_bc_socket() !net.Socket {

    // Create a UDP socket
    sock = try net.Socket.create(.ipv4, .udp);
    try sock.setBroadcast(true);
    try sock.setReadTimeout(100000);

    return sock;
}

pub fn udp_revert_socket() !void {
    try sock.setBroadcast(false);
    try sock.setReadTimeout(100000);
    try sock.setReadBuffSz(192000);
    try sock.setSendBuffSz(192000);
}

pub fn udp_close_socket() !void {
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

