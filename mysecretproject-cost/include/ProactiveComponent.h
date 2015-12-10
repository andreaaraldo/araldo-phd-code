//<aa>
#ifndef PROACTIVE_COMPONENT_H_
#define PROACTIVE_COMPONENT_H_

#include "ccnsim.h"
#include "client.h"
#include "error_handling.h"

using namespace std;

class ProactiveComponent:public client
{
    public:
		virtual void initialize();
		void try_to_improve(chunk_t stored, chunk_t requested_chunk_id);
		void proactively_catch_a_chunk(chunk_t object_id, cnumber_t chunk_num,
		        representation_mask_t repr_mask);

    protected:
		virtual void request_specific_chunk(name_t object_id, cnumber_t chunk_num,
		        representation_mask_t repr_mask);
		double proactive_probability;
};
#endif
//</aa>
