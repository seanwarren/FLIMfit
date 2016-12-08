//=========================================================================
//
// Copyright (C) 2013 Imperial College London.
// All rights reserved.
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
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// This software tool was developed with support from the UK 
// Engineering and Physical Sciences Council 
// through  a studentship from the Institute of Chemical Biology 
// and The Wellcome Trust through a grant entitled 
// "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
//
// Author : Sean Warren
//
//=========================================================================

#pragma warning(disable: 4244 4267)

#include "FitController.h"
#include "FitStatus.h"
#include "InstrumentResponseFunction.h"
#include "ModelADA.h" 
#include "FLIMGlobalAnalysis.h"
#include "FLIMData.h"
#include "tinythread.h"
#include <assert.h>
#include <utility>

#include <memory>
#include <string>
#include "MexUtils.h"
#include "PointerMap.h"

using std::string;

PointerMap<FitController> pointer_map;

void setFitSettings(shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(mxIsStruct(prhs[2]));

   FitSettings settings;

   settings.global_algorithm = getValueFromStruct(prhs[2],"global_algorithm", 0);
   settings.global_mode = getValueFromStruct(prhs[2], "global_mode", 0);
   settings.algorithm = getValueFromStruct(prhs[2], "algorithm", 0);
   settings.weighting = getValueFromStruct(prhs[2], "weighting");
   settings.n_thread = getValueFromStruct(prhs[2], "n_thread", 4);
   settings.run_async = getValueFromStruct(prhs[2], "run_async", 1);

   int calculate_errors = getValueFromStruct(prhs[2], "calculate_errors", 0);
   double conf_interval = getValueFromStruct(prhs[2], "conf_interval", 0.05);
   settings.setCalculateErrors(calculate_errors, conf_interval);

   c->setFitSettings(settings);
}

void setData(shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);

   auto data = GetSharedPtrFromMatlab<FLIMData>(prhs[2]);
   c->setData(data);
}

void setModel(shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   
   auto model = GetSharedPtrFromMatlab<QDecayModel>(prhs[2]);
   c->setModel(model);
}

void startFit(shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{   
   c->init();
   c->runWorkers();
}

void getFit(shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nrhs >= 3);
   AssertInputCondition(nlhs >= 3);

   // TODO

   //int im = mxGetScalar(prhs[2]);
   //int fit_mask[]= mxGetScalar(prhs[2]);  
   //double fit[]= mxGetScalar(prhs[2]);  
   //int* n_valid;
   
   //c->GetFit(im, n_fit, fit_mask, fit, *n_valid);
}

void clearFit(shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   c->init();
   c->runWorkers();
}

void stopFit(shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   c->stopFit();
}

void getFitStatus(shared_ptr<FitController> c, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   AssertInputCondition(nlhs >= 2);
   
   auto reporter = c->getProgressReporter();

   plhs[0] = mxCreateDoubleScalar(reporter->getProgress());
   plhs[1] = mxCreateLogicalScalar(reporter->isFinished());

   //const char* labels[] = { "group", "n_completed", "iter", "chi2" };
   //plhs[2] = mxCreateStructMatrix(1, 1, 4, labels);

   /* TODO
   //   int n_thread = c->status->n_thread;
   plhs[1] = mxCreateDoubleMatrix(1, n_thread, mxREAL);
   plhs[2] = mxCreateDoubleMatrix(1, n_thread, mxREAL);
   plhs[3] = mxCreateDoubleMatrix(1, n_thread, mxREAL);
   plhs[4] = mxCreateDoubleMatrix(1, n_thread, mxREAL);

   double* group = mxGetPr(plhs[1]);
   double* n_completed = mxGetPr(plhs[2]);
   double* iter = mxGetPr(plhs[3]);
   double* chi2 = mxGetPr(plhs[4]);

   for (int i = 0; i<c->status->n_thread; i++)
   {
      group[i] = c->status->group[i];
      n_completed[i] = c->status->n_completed[i];
      iter[i] = c->status->iter[i];
      chi2[i] = c->status->chi2[i];
   }
   */
}



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   try
   {
      if (nrhs == 0 && nlhs > 0)
      {
         AssertInputCondition(nlhs > 0);
         int idx = pointer_map.CreateObject();
         plhs[0] = mxCreateDoubleScalar(idx);
         return;
      }

      AssertInputCondition(nrhs >= 2);
      AssertInputCondition(mxIsScalar(prhs[0]));
      AssertInputCondition(mxIsChar(prhs[1]));

      int c_idx = mxGetScalar(prhs[0]);

      // Get controller
      auto controller = pointer_map.Get(c_idx);
      if (controller == nullptr)
         mexErrMsgIdAndTxt("FLIMfitMex:invalidControllerIndex", "Controller index is not valid");

      // Get command
      string command = GetStringFromMatlab(prhs[1]);

      if (command == "Clear")
         pointer_map.Clear(c_idx);
      else if (command == "SetFitSettings")
         setFitSettings(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "SetData")
         setData(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "SetModel")
         setModel(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "StartFit")
         startFit(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "StopFit")
         stopFit(controller, nlhs, plhs, nrhs, prhs);
      else if (command == "GetFitStatus")
         getFitStatus(controller, nlhs, plhs, nrhs, prhs);

   }
   catch (std::runtime_error e)
   {
      mexErrMsgIdAndTxt("FLIMReaderMex:exceptionOccurred",
         e.what());
   }
}
 




