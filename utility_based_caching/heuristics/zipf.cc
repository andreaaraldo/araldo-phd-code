#include "zipf.h"

using namespace std;

float alpha=1;
unsigned long ctlg=100;

int main(int,char*[])
{
	float alpha=1;
	unsigned long ctlg = 200;
	unsigned seed = 1;
	unsigned long tot_requests = 100;
	ZipfGenerator zipf(alpha, ctlg, seed,tot_requests);
	cout<<zipf.generate_requests(1)<<" "<<zipf.generate_requests(1)<<" "<<zipf.generate_requests(1)<<" "<<endl;
	cout<<zipf.generate_requests(2)<<" "<<zipf.generate_requests(2)<<" "<<zipf.generate_requests(2)<<" "<<endl;
}
