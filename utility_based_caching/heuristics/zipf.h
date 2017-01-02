#include <iostream>
#include <map>
#include <utility>
#include <random>
#include <cmath>

// See http://www.cplusplus.com/reference/random/poisson_distribution/operator()/

class KnownHarmNum{
	private:
		std::map< std::pair<float, unsigned long>, float > table;

	public:
		KnownHarmNum()
		{
			table.emplace( std::pair<float, unsigned long>(1,10  ), 2.82897);
			table.emplace( std::pair<float, unsigned long>(1,100 ), 5.17738);
			table.emplace( std::pair<float, unsigned long>(1,1000), 7.48448);
		}
	
	// Returns a negative number if the harmonic number is not known
		float get(float alpha, unsigned long ctlg)
		{
			float harm_num = -1;
			std::map< std::pair<float, unsigned long>, float >::iterator it = 
				table.find(std::pair<float, unsigned long>(alpha,ctlg) );
			if (it != table.end() )
				harm_num = it->second;
			return harm_num; 
		}
};

class ZipfGenerator
{
	private:
		float alpha_;
		unsigned long ctlg_;
		float harm_num_;
		std::default_random_engine generator_;
		unsigned long avg_tot_requests_;

	public:
		ZipfGenerator(const float alpha, const unsigned long ctlg, const unsigned seed,
			const unsigned long avg_tot_requests
		){
			alpha_=alpha;
			ctlg_=ctlg;
			avg_tot_requests_ = avg_tot_requests;
			harm_num_ = (new KnownHarmNum() )->get(alpha,ctlg);
			if (harm_num_ < 0)
			{	// I need to compute it
				harm_num_ = 0;
				for (unsigned long i=1; i<ctlg; i++)
					harm_num_ += 1/pow(i,alpha);
				std::cout<<"harm_num("<<alpha<<","<<ctlg<<")="<< harm_num_ <<std::endl;
			}
			generator_ = std::default_random_engine(seed);
		}

		unsigned long generate_requests(unsigned long obj)
		{
			float prob = harm_num_ * 1/ pow(obj,alpha_);
			float avg_requests = prob * avg_tot_requests_;
			std::poisson_distribution<unsigned> distribution(avg_requests);
			return distribution(generator_);
		}

};
