/*
 This is a better implementation since we interleave I/O operations from hard disk with computation requiring no I/O. The two activities can run in parallel.
*/


#include <iostream>
#include <thread>
#include <cmath>
#include <mutex>
#include <condition_variable>
using namespace std;
#define SEVERE_DEBUG



unsigned num_threads = 8;
unsigned num_params = 9;

// I assume we already know the number of lines 
// Otherwise, it would in any case be easy to compute them
unsigned long data_rows = 1048576-1; 

class semaphore
{
	public:

	  semaphore(long int last_row_read_ = -1) : last_row_read{last_row_read_}
	  {}

	  void notify()
	  {
		std::unique_lock<std::mutex> lck(mtx);
		++last_row_read;
		cv.notify_all();
	  }

	  void wait(long int wanna_read)
	  {
		unique_lock<std::mutex> lck(mtx);
		while(wanna_read > last_row_read)
		{
		  cv.wait(lck);
		}

	  }

	private:
	  std::mutex mtx;
	  std::condition_variable cv;
	  long int last_row_read;
};



float* density = (float*) malloc(sizeof(float)*data_rows);
float* fwdVel = (float*) malloc(sizeof(float)*data_rows);
float* leadVehVel = (float*) malloc(sizeof(float)*data_rows);
float* alpha = (float*) malloc(sizeof(float)*data_rows);
float* beta = (float*) malloc(sizeof(float)*data_rows);
float* gamma_ = (float*) malloc(sizeof(float)*data_rows);
float* lambda = (float*) malloc(sizeof(float)*data_rows);
float* rho = (float*) malloc(sizeof(float)*data_rows);
float* stddev = (float*) malloc(sizeof(float)*data_rows);
float* result = (float*) malloc(sizeof(float)*data_rows);

semaphore* s = new semaphore();


void process_file(unsigned id) 
{
	for(long int wanna_read=id; wanna_read<=data_rows; wanna_read+=num_threads)
	{
		printf(" w%ld", wanna_read);
		s->wait(wanna_read);
		printf(" r%ld", wanna_read);
		float dv = abs(fwdVel[wanna_read] - leadVehVel[wanna_read]);
		float a = pow(fwdVel[wanna_read], (beta[wanna_read]/gamma_[wanna_read]));
		float b = pow(dv, lambda[wanna_read]);
		float c = pow(density[wanna_read],rho[wanna_read]);
		result[wanna_read] = alpha[wanna_read] * a * b * c;
		printf(" s%ld", wanna_read);
	}
}

int main() {
	std::thread t[num_threads];

	//lunch all the threads
	for (unsigned id=0; id<num_threads; id++)
		t[id] = std::thread(process_file, id);


	FILE *fp = fopen("Data.csv", "r");
	if( !fp )
	{
		printf("Error in reading file\n");
		return 1;
	}
		//skip the header
		while (getc(fp)!= '\n' ){};
		unsigned short howmanyreads;
		for (unsigned long i=0; i<data_rows; i++)
		{
			howmanyreads=fscanf(fp, "%f,%f,%f,%f,%f,%f,%f,%f,%f\n", 
				density+i, fwdVel+i, leadVehVel+i, alpha+i, beta+i, gamma_+i,
				lambda+i, rho+i, stddev+i);

			printf(" +%lu",i);
			s->notify();
			printf(" n%lu",i);

			#ifdef SEVERE_DEBUG
			if (howmanyreads != num_params)
			{
				printf("ERROR: not all the parameters have been read\n");
				exit(0);
			}
			#endif
		}
	fclose(fp);

	for (unsigned id=0; id<num_threads; id++)
	{
		t[id].join();
	}

	/* WRITE RESULT FILE{ */
	fp = fopen("result.csv", "w");
	if( !fp )
	{
		printf("Error in writing file\n");
		return 1;
	}
	fprintf(fp,"This is the result file\n");
	for (unsigned long i=0; i<data_rows; i++)
	{
		fprintf(fp,"%f\n",result[i]);
	}
	fclose(fp);
	printf("End\n");
	/* }WRITE RESULT FILE */

	return 0;
}
