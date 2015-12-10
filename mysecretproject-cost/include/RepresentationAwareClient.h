/*
 * ccnSim is a scalable chunk-level simulator for Content Centric
 * Networks (CCN), that we developed in the context of ANR Connect
 * (http://www.anr-connect.org/)
 *
 * People:
 *    Giuseppe Rossini (lead developer, mailto giuseppe.rossini@enst.fr)
 *    Raffaele Chiocchetti (developer, mailto raffaele.chiocchetti@gmail.com)
 *    Dario Rossi (occasional debugger, mailto dario.rossi@enst.fr)
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
#ifndef REPRESENTATIONAWARE_CLIENT_H_
#define REPRESENTATIONAWARE_CLIENT_H_

#include <omnetpp.h>
#include "ccnsim.h"
#include "client.h"
using namespace std;

class RepresentationAwareClient : public client
{
	public:
		virtual void clear_stat();
		const virtual long unsigned* get_repr_downloaded() const;

	protected:
		virtual void initialize();
		virtual bool handle_incoming_chunk (ccn_data *data_message);

	private:
		long unsigned* repr_downloaded;	// repr_downloaded[i] counts the number of objects downloaded
											// at representation i+1
};
#endif
