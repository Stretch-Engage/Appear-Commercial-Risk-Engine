public with sharing class DnbService {

    public static String fetchCompanyData(String duns, String blockGroupName, String countryCode) {

        if (String.isBlank(duns)) {
            throw new IllegalArgumentException('DUNS number cannot be blank');
        }

        Dnb_Block_Group__mdt config =
            Dnb_Block_Group__mdt.getInstance(blockGroupName);

        if (config == null || !config.Active__c) {
            throw new IllegalArgumentException(
                'Block group not found or inactive: ' + blockGroupName
            );
        }

        String blockIds = config.Block_IDs__c;

        HttpRequest req = new HttpRequest();

        String endpoint = 'callout:DNB_Direct_Plus/v1/data/duns/' +
                          duns +
                          '?blockIDs=' +
                          EncodingUtil.urlEncode(blockIds, 'UTF-8');

                 // Germany-specific parameters
                if (countryCode != null && countryCode == 'DE') {
                    endpoint +=
                        '&tradeUp=hq' +
                        '&customerReference=' +
                        EncodingUtil.urlEncode('SF-' + duns, 'UTF-8') +
                        '&orderReason=6332';
                }

        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new CalloutException(
                'DNB call failed. Status: ' +
                res.getStatusCode() +
                ' Body: ' +
                res.getBody()
            );
        }

        return res.getBody();
    }
}