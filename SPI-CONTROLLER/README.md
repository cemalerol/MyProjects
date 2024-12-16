Bir SPI denetleyicisi tasarlayarak mantık devresi ile çevre birimi (örn. ADC converter) arasındaki iletişimi in-out  port üzerinden sağladım. 
Denetleyici, çevresel bir cihaz ile harici bir mantık devresi arasında veri okuma/yazma işlemleri gerçekleştirerek iletişim sağlar.
Denetleyici, yalnızca bir kez okuma veya yazma işlemi gerçekleştirir ve işlem tamamlandıktan sonra başlangıç durumuna döner.
Seri veri alışverişi, 1 MHz SPI saati (SCLK) yükselen kenarı ile senkronize olarak SDIO pini üzerinden gerçekleştirilir; CSB pini ise çevresel iletişimi etkinleştirir veya devre dışı bırakır.
DATA_IN sinyali, işlemin komut ve adres bilgilerini belirlerken, işlenmiş veri DATA_OUT sinyalinde harici mantık için kullanıma sunulur.

I designed an SPI controller to establish communication between the logic circuit and a peripheral device (e.g., ADC converter) through the in-out port.
The controller facilitates data read/write operations between the peripheral device and the external logic circuit.
The controller performs a read or write operation only once and returns to its initial state after the operation is completed.
Serial data exchange is carried out via the SDIO pin, synchronized with the rising edge of the 1 MHz SPI clock (SCLK), while the CSB pin enables or disables the peripheral communication.
The DATA_IN signal specifies the command and address information for the operation, while the processed data is made available on the DATA_OUT signal for use by the external logic.