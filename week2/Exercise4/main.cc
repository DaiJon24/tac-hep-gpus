#include <stdio.h>
#include <iostream>
#include <vector>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "t1.h"

#include <TMath.h>
#include <TFile.h>
#include <TTree.h>
#include <TH1F.h>
#include <TCanvas.h> 
#include <TLorentzVector.h>



//------------------------------------------------------------------------------
// Particle Class
//
class Particle{

	public:
	Particle();
	// FIXME : Create an additional constructor that takes 4 arguments --> the 4-momentum
	double   pt, eta, phi, E, m, p[4];
	void     p4(double, double, double, double);
	void     print();
	void     setMass(double);
	double   sintheta();

};

//------------------------------------------------------------------------------

//*****************************************************************************
//                                                                             *
//    MEMBERS functions of the Particle Class                                  *
//                                                                             *
//*****************************************************************************

//
//*** Default constructor ------------------------------------------------------
//
Particle::Particle(){
	pt = eta = phi = E = m = 0.0;
	p[0] = p[1] = p[2] = p[3] = 0.0;
}

//*** Additional constructor ------------------------------------------------------
Particle::Particle(double pt_, double eta_, double phi_, double E_){
	p4(pt_, eta_, phi_, E_);
}

//
//*** Members  ------------------------------------------------------
//
double Particle::sintheta(){
	double theta = 2.0 * atan(exp(-eta));
	return sin(theta);
}

void Particle::p4(double pT, double eta_, double phi_, double energy){

	pt = pT;
	eta = eta_;
	phi = phi_;
	E = energy;
	p[0] = pt*cos(phi);
	p[1] = pt*sin(phi);
	p[2] = pt*sinh(eta);
	p[3] = E;

	double p2=p[0]*p[0]+p[1]*p[1]+p[2]*p[2];
	m=sqrt(E*E-p2);

}

void Particle::setMass(double mass)
{
	m=mass;
}

//
//*** Prints 4-vector ----------------------------------------------------------
//
void Particle::print(){
	std::cout << std::endl;
	std::cout << "(" << p[0] <<",\t" << p[1] <<",\t"<< p[2] <<",\t"<< p[3] << ")" << "  " <<  sintheta() << std::endl;
}

class lepton : public Particle{
	public:
	lepton();
	int charge;
	void setCharge(int q);
};
lepton::lepton() : Particle(){
	charge = 0;
}
void lepton::setCharge(int q){
	charge = q;
}

class jet : public Particle{
	public:
	jet();
	int flavour;
	void setFlavour(int f);
};
jet::jet() : Particle(){
	flavour = 0;
}
void jet::setFlavour(int f){
	flavour = f;
}
int main() {
	
	/* ************* */
	/* Input Tree   */
	/* ************* */

	TFile *f      = new TFile("input.root","READ");
	TTree *t1 = (TTree*)(f->Get("t1"));

	// Read the variables from the ROOT tree branches
	t1->SetBranchAddress("lepPt",&lepPt);
	t1->SetBranchAddress("lepEta",&lepEta);
	t1->SetBranchAddress("lepPhi",&lepPhi);
	t1->SetBranchAddress("lepE",&lepE);
	t1->SetBranchAddress("lepQ",&lepQ);
	
	t1->SetBranchAddress("njets",&njets);
	t1->SetBranchAddress("jetPt",&jetPt);
	t1->SetBranchAddress("jetEta",&jetEta);
	t1->SetBranchAddress("jetPhi",&jetPhi);
	t1->SetBranchAddress("jetE", &jetE);
	t1->SetBranchAddress("jetHadronFlavour",&jetHadronFlavour);

	// Total number of events in ROOT tree
	Long64_t nentries = t1->GetEntries();

	for (Long64_t jentry=0; jentry<100;jentry++)
 	{
		t1->GetEntry(jentry);
		std::cout<<" Event "<< jentry <<std::endl;	

		//FIX ME
		// Create a vector of leptons and a vector of jets
		std::vector<lepton> leptons;
		std::vector<jet> jets;

		// Fill the vectors with the corresponding particles
		lepton l;
		l.p4(lepPt, lepEta, lepPhi, lepE);
		l.setCharge(lepQ);
		leptons.push_back(l);

		for (int i = 0; i < njets; i++) {
			jet j;
			j.p4(jetPt[i], jetEta[i], jetPhi[i], jetE[i]);
			j.setFlavour(jetHadronFlavour[i]);
			jets.push_back(j);
		}
		// Print the particles
		std::cout << "Leptons: " << std::endl;
		for (size_t i = 0; i < leptons.size(); i++) {
			leptons[i].print();
		}
		std::cout << "Jets: " << std::endl;
		for (size_t i = 0; i < jets.size(); i++) {
			jets[i].print();
		}
	} // Loop over all events

  	return 0;
}
