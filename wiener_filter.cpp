#include <iostream>
#include <fstream>
#include <cmath>
#include <iomanip>
#include <string>

using namespace std;

#define MAX_SIZE 500
double R[MAX_SIZE][MAX_SIZE];
double crosscorr[MAX_SIZE];

void computeAutocorrelation(double signal[MAX_SIZE], double autocorr[MAX_SIZE], int N) {
    // TODO
    int M = 500;
    if (N < M) M = N;
    for (int k = 0; k < M; k++)
    {
        double sum = 0;
        for (int n = k; n < N; n++)
        {
            sum += (signal[n] * signal[n - k]);
        }
        autocorr[k] = sum / N;
    }
}

// Hàm tính crosscorrelation giữa desired signal và input signal
void computeCrosscorrelation(double desired[MAX_SIZE], double input[MAX_SIZE], double crosscorr[MAX_SIZE], int N) {
    // TODO
    int M = 500;
    if (N < M) M = N;
    for (int k = 0; k < M; k++)
    {
        double sum = 0;
        for (int n = k; n < N; n++)
        {
            sum += desired[n] * input[n - k];
        }
        crosscorr[k] = sum / N;
    }
}

// Hàm tạo ma trận Toeplitz từ autocorrelation
void createToeplitzMatrix(double autocorr[MAX_SIZE], double R[MAX_SIZE][MAX_SIZE], int N) {
    // TODO
    int M = 500;
    if (N < M) M = N;
    for (int i = 0; i < M; i++)
    {
        for (int j = 0; j < M; j++)
        {
            R[i][j] = autocorr[abs(i - j)];
        }
    }
}

// Giải hệ phương trình tuyến tính bằng Gauss elimination
void solveLinearSystem(double A[MAX_SIZE][MAX_SIZE], double b[MAX_SIZE], double x[MAX_SIZE], int N) {
    // TODO
    int M = 500;
    if (N < M) M = N;
    double Aug[M][M + 1];
    for (int i = 0; i < M; i++)
    {
        for (int j = 0; j < M; j++)
        {
            Aug[i][j] = A[i][j];
        }
    }
    for (int i = 0; i < M; i++)
    {
        Aug[i][M] = b[i];
    }

    for (int k = 0; k < M; k++)
    {
        int p = k;
        double MaxValue = fabs(Aug[k][k]);
        for (int i = k + 1; i < M; i++) 
        {
            if (fabs(Aug[i][k]) > MaxValue)  
            {
                p = i;
                MaxValue = fabs(Aug[i][k]);
            }
        }
        if (p != k) {
            for (int j = 0; j <= M; j++) {
                double temp = Aug[p][j];
                Aug[p][j] = Aug[k][j];
                Aug[k][j] = temp;
            }
        }

        for (int i = k + 1; i < M; i++)
        {
            double factor = Aug[i][k] / Aug[k][k];
            Aug[i][k] = 0;
            for (int j = k + 1; j <= M; j++)
            {
                Aug[i][j] = Aug[i][j] - factor * Aug[k][j];
            }
        }
    }

    for (int i = M - 1; i >= 0; i--)
    {
        double s = Aug[i][M];
        for (int j = i + 1; j < M; j++)
        {
            s = s - Aug[i][j] * x[j];
        }
        x[i] = s / Aug[i][i];
    }
}

// Tính hệ số Wiener
void computeWienerCoefficients(double desired[MAX_SIZE], double input[MAX_SIZE], int N, double coefficients[MAX_SIZE]) {
    double autocorr[MAX_SIZE];
    
    

    computeAutocorrelation(input, autocorr, N);
    computeCrosscorrelation(desired, input, crosscorr, N);
    createToeplitzMatrix(autocorr, R, N);
    solveLinearSystem(R, crosscorr, coefficients, N);
}

// Áp dụng Wiener filter
void applyWienerFilter(double input[MAX_SIZE], double coefficients[MAX_SIZE], double output[MAX_SIZE], int N) {
    // TODO
    int M = 500;
    if (N < M) M = N;
    for (int n = 0; n < N; n++) {
        output[n] = 0;
        for (int k = 0; k < M; k++) {
            if (n >= k) {
                output[n] += coefficients[k] * input[n - k];
            }
        }
    }
}

// Tính MMSE
double computeMMSE(double desired[MAX_SIZE], double output[MAX_SIZE], int N) {
    double mse = 0;
    for (int n = 0; n < N; n++) {
        double error = desired[n] - output[n];
        mse += error * error;
    }
    return mse / N;
}

// Đọc file
int readSignalFromFile(const string &filename, double signal[MAX_SIZE]) {
    ifstream file(filename);
    if (!file.is_open()) throw runtime_error("Cannot open file: " + filename);

    int count = 0;
    double value;
    while (file >> value && count < MAX_SIZE) {
        signal[count++] = value;
    }
    file.close();
    return count;
}

// Ghi file
void writeOutputToFile(const string &filename, double output[MAX_SIZE], int N, double mmse, double R[MAX_SIZE][MAX_SIZE], double coefficients[MAX_SIZE]) {
    ofstream file(filename);
    if (!file.is_open()) throw runtime_error("Cannot open file: " + filename);

   file << "Filtered output: ";
    for (int i = 0; i < N; i++) {
        double rounded = std::round(output[i] * 10.0) / 10.0;

        // fix -0.0 thành 0.0
        if (rounded == 0.0) rounded = 0.0;

        file << fixed << setprecision(1) << rounded;
        if (i != N - 1) file << ' ';
    }
    file << endl;

    double rounded_mmse = std::round(mmse * 10.0) / 10.0;
    if (rounded_mmse == 0.0) rounded_mmse = 0.0;

    file << "MMSE: " << fixed << setprecision(1) << rounded_mmse;

    file << "\nR:" << endl;

    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            file << R[i][j] << ' ';
        }
        file << endl;
    }

    file << "crosscorr" << endl;
    for (int i = 0; i < 10; i++)
    {
        file << crosscorr[i] << ' ';
    }
    file << endl;

    file << "coefficients" << endl;
    for (int i = 0; i < 10; i++)
    {
        file << coefficients[i] << ' ';
    }
    
    

    file.close();
}

int main()
{
    try
    {
        double desired[MAX_SIZE], input[MAX_SIZE], output[MAX_SIZE], coefficients[MAX_SIZE];

        int SIZE = readSignalFromFile("desired.txt", desired);
        int N2 = readSignalFromFile("input.txt", input);

        if (SIZE != N2)
        {
            ofstream errorFile("output.txt");
            errorFile << "Error: size not match" << endl;
            errorFile.close();
            cerr << "Error: size not match" << endl;
            return 0;
        }

        computeWienerCoefficients(desired, input, SIZE, coefficients);
        applyWienerFilter(input, coefficients, output, SIZE);
        double mmse = computeMMSE(desired, output, SIZE);
        writeOutputToFile("output.txt", output, SIZE, mmse, R, coefficients);
        
        system("type output.txt");
    }
    catch (const exception &e)
    {
        cerr << "Error: " << e.what() << endl;
        ofstream errorFile("output.txt");
        errorFile << e.what() << endl;
        errorFile.close();
        return 1;
    }

    return 0;
}