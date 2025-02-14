import Network

enum DnsLookupFamily {
    case ipv4
    case ipv6
    case unspec

    func toCFamily() -> Int32 {
        switch self {
        case .ipv4:
            return AF_INET
        case .ipv6:
            return AF_INET6
        case .unspec:
            return AF_UNSPEC
        }
    }
}

func performDnsLookup(host: String, family: DnsLookupFamily) -> String? {
    var hints = addrinfo(
        ai_flags: 0,
        ai_family: family.toCFamily(),
        ai_socktype: SOCK_DGRAM,
        ai_protocol: 0,
        ai_addrlen: 0,
        ai_canonname: nil,
        ai_addr: nil,
        ai_next: nil
    )
    
    var infoPointer: UnsafeMutablePointer<addrinfo>?
    let status = getaddrinfo(host, nil, &hints, &infoPointer)
    guard status == 0 else {
        logger.error("dns: Lookup of \(host) failed with \(String(cString: gai_strerror(status)))")
        return nil
    }

    defer { freeaddrinfo(infoPointer) }  // ✅ Automatically frees memory on function exit

    var addresses: [String] = []
    var pointer = infoPointer

    while let addrInfo = pointer?.pointee {
        if let address = addrInfo.ai_addr {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(
                address,
                socklen_t(addrInfo.ai_addrlen),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            ) == 0 {
                addresses.append(String(cString: hostname))
            }
        }
        pointer = addrInfo.ai_next
    }

    addresses.forEach { logger.info("dns: Found address \($0) for \(host)") }
    return addresses.first
}
