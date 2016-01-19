#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <QFileDialog>
#include <QImage>
#include <QDebug>

#include "medianfilter.h"


#include <chrono>
#include <cstdlib>

/** Prosty timer */
class Timer
{
    decltype(std::chrono::steady_clock::now()) mBegin = std::chrono::steady_clock::now();
    decltype(std::chrono::steady_clock::now()- std::chrono::steady_clock::now()) mDiff ;

public:
    void start()
    {
        mBegin = std::chrono::steady_clock::now();
    }

    void stop()
    {
        mDiff = std::chrono::steady_clock::now() - mBegin;
    }

    double measured() const
    {
        return std::chrono::duration <double, std::milli>(mDiff).count();
    }
};

static void test()
{
    Timer timer;
    unsigned char array[9];
    double timeQuick = 0, timeNormal = 0;
    const unsigned TESTS = 1000000;

    for (unsigned i = 0; i < TESTS; ++i)
    {
        for (unsigned char &c : array)
            c = std::rand() % 256;


        timer.start();
        median(array, 9);
        timer.stop();
        timeNormal += timer.measured();

        timer.start();
        quickMedian(array, 9);
        timer.stop();
        timeQuick += timer.measured();
    }
    qDebug() << "Time normal: " << timeNormal;
    qDebug() << "Time quick: " << timeQuick;


}

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    test();
    ui->setupUi(this);

    ui->graphicsView->setScene(&scene);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_actionOpen_triggered()
{
    QString path = QFileDialog::getOpenFileName(this, "Wskaż plik graficzny");

    QImage qsrc, qdst;
    Image src, dst;

    qsrc.load(path);
    qdst = qsrc;
    qdst.detach();

    src.data = qsrc.bits();
    dst.data = qdst.bits();
    src.height = dst.height = qsrc.height();
    src.width = dst.width = qsrc.width();
    medianFilter(&src, &dst, qsrc.byteCount()/(qsrc.height()*qsrc.width()));

    scene.addPixmap(QPixmap::fromImage(qdst));
    scene.setSceneRect(qdst.rect());

}
