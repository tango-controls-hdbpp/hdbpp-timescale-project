// Copyright (C) : 2014-2017
// European Synchrotron Radiation Facility
// BP 220, Grenoble 38043, FRANCE
//
// This file is part of HdbppHealthCheck
//
// HdbppHealthCheck is free software: you can redistribute it and/or modify
// it under the terms of the Lesser GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// HdbppHealthCheck is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the Lesser
// GNU General Public License for more details.
//
// You should have received a copy of the Lesser GNU General Public License
// along with HdbppHealthCheck.  If not, see <http://www.gnu.org/licenses/>.


#include "HealthCheck.h"

#include "httplib.h"
#include "rapidjson/document.h"
#include <tango.h>
#include <iostream>

namespace HdbppHealthCheck_ns
{

//=============================================================================
//=============================================================================
bool HealthCheck::configure_rest_server_address(const std::string &host, int port, const std::string &root_url)
{
    if (host.empty() || root_url.empty())
        return false;

    _host = host;
    _port = port;
    _root_url = root_url;

    // quickly check if the given details can connect to a a server
    httplib::Client cli(_host, _port);
    auto url = _root_url + "/";
    auto result = cli.Get(url.c_str());

    return !(result == nullptr);
}

//=============================================================================
//=============================================================================
std::tuple<HealthCheck::HealthCheckResult, std::string> HealthCheck::check_hosts() const
{
    assert(!_host.empty());
    assert(!_root_url.empty());

    if (!_hosts_check_enabled)
        Tango::Except::throw_exception("Bad Configuration", 
            "Attempting to check hosts when it has not been configured", (const char *)__func__);

    // contact the cluster reporting server and request the server
    // health status
    httplib::Client cli(_host, _port);
    auto url = _root_url + "/health/servers";
    auto result = cli.Get(url.c_str());
    
    if (result && result->status == 200) 
    {
        rapidjson::Document document;
        document.Parse(result->body.c_str());

        if (!document.IsObject() || !document["state"].IsString() || document.HasMember("state"))
            return std::make_tuple(HealthCheckResult::ConnectionProblem, invalid_response);

        // Retrieve the error message if there is any
	std::string error_message;
	if (document.HasMember("message") && document["message"].IsString())
            error_message = "\n" + std::string(document["message"].GetString());
	
        else
            error_message = "";

        // get a valid reponse, now check the cluster
        if (document["state"] == "Ok")
            return std::make_tuple(HealthCheckResult::Ok, server_no_errors + error_message);

        else if (document["state"] == "Warning")
            return std::make_tuple(HealthCheckResult::Warning, server_warning + error_message);

        else if (document["state"] == "Error") 
            return std::make_tuple(HealthCheckResult::Error, server_error + error_message);

        else
            return std::make_tuple(
                HealthCheckResult::ConnectionProblem, server_bad_response + error_message);
    }

    return std::make_tuple(HealthCheckResult::ConnectionProblem, no_reponse);
}

} // namespace HdbppHealthCheck_ns
