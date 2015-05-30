#pragma once

#include "FLIMImage.h"
#include "ProgressReporter.h"
#include "FLIMImageSet.h"
#include "FLIMReader.h"

#include <QObject>
#include <QFileInfoList>
#include <QFileDialog>
#include <QString>
#include <QDir>
#include <vector>
#include <memory>
#include <cstdint>

class FileSet
{
public:
   QFileInfoList files;
   int n_channels;
};

class FLIMImporter : public QObject
{
   Q_OBJECT
   
public:
   
   FLIMImporter();
   
   std::shared_ptr<InstrumentResponseFunction> importIRFFromDialog();
   std::shared_ptr<InstrumentResponseFunction> importIRF(const QString& filename);
   std::shared_ptr<FLIMImageSet> importFromFolder(const QString& folder, const vector<int>& channels, const QString& project_folder = 0);
   std::shared_ptr<FLIMImageSet> importFromFolder(const QString& folder, const QStringList file_names, const vector<int>& channels, const QString& project_folder = 0);
   FileSet getValidFilesFromFolder(const QString& folder);
   
   template <typename T>
   std::shared_ptr<FLIMImageSet> importFiles(QFileInfoList files, const vector<int>& channels, const QString& root);
   
   template <typename T>
   std::shared_ptr<FLIMImage> importStackedFiles(QStringList stack_files, const QString& root, const std::vector<int>& channels);

   void setStackSize(int n_stack_) { n_stack = n_stack_; }
   int getStackSize() { return n_stack; }
   
   std::shared_ptr<ProgressReporter> getProgressReporter() { return reporter; }
   
protected:
   
   QStringList filters;
   std::shared_ptr<ProgressReporter> reporter;
   int n_stack = 1;
};


template <typename T>
std::shared_ptr<FLIMImageSet> FLIMImporter::importFiles(QFileInfoList files, const vector<int>& channels, const QString& root)
{
   auto images = std::make_shared<FLIMImageSet>();
   
   int n_tasks = (files.size() / n_stack) * (n_stack + 2); // + 2 for setup image, compute intensity etc at end
   reporter = std::make_shared<ProgressReporter>("Reading Files", n_tasks);
   
   std::vector<std::future<std::shared_ptr<FLIMImage>>> futures;
   for (int i=0; (i+n_stack)<=files.size(); i+=n_stack)
   {
      QStringList stack_files;
      for (int j=0; j<n_stack; j++)
         stack_files.push_back(files[i+j].absoluteFilePath());
      
      auto image = importStackedFiles<T>(stack_files, root, channels);
      images->addImage(image);
   }
   return images;
}

template <typename T>
std::shared_ptr<FLIMImage> FLIMImporter::importStackedFiles(QStringList stack_files, const QString& root, const std::vector<int>& channels)
{
   assert(!stack_files.empty());
   std::string file = stack_files[0].toStdString();
   auto reader = std::shared_ptr<FLIMReader>(FLIMReader::createReader(file));
   //reader->setTemporalResolution(8);
   
   auto acq = std::make_shared<AcquisitionParameters>(0, 12500);
   acq->n_chan = channels.size() * stack_files.size();
   acq->setImageSize(reader->numX(), reader->numY());
   acq->setT(reader->timepoints());
   reader = nullptr;
   
   QFileInfo info(stack_files[0]);
   std::string basename = info.baseName().toStdString();
   
   auto image = std::make_shared<FLIMImage>(acq, typeid(T), basename, FLIMImage::DataMode::MappedFile, root.toStdString());
   std::shared_ptr<ProgressReporter> rep = reporter;
   rep->subTaskCompleted();
   
   auto read_fcn = [image, reader, stack_files, channels, rep]()
   {
      if (image->hasData())
         return;
      
      auto acq = image->getAcquisitionParameters();
      int n_stack = stack_files.size();
      int channel_stride = n_stack * channels.size();
      
      size_t sz = image->getImageSizeInBytes();
      vector<char> data_buf(sz);
      T* data_ptr = reinterpret_cast<T*>(data_buf.data());
      
      for (int j=0; j<n_stack; j++)
      {
         std::string file = stack_files[j].toStdString();
         auto reader = std::unique_ptr<FLIMReader>(FLIMReader::createReader(file));
         //reader->setTemporalResolution(8);
         
         T* next_ptr = data_ptr + j * channels.size() * acq->n_t_full;
         reader->readData(next_ptr, channels, channel_stride);
         
         rep->subTaskCompleted();
      }
      
      T* img_ptr = image->getDataPointer<T>();
      memcpy(img_ptr, data_ptr, sz);
      image->releaseModifiedPointer<T>();
      rep->subTaskCompleted();
   };
   image->setReadFuture(std::async(std::launch::async, read_fcn).share());
   
   return image;
}
